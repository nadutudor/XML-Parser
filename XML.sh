#!/bin/bash

declare -A children
declare -A valori
declare -a stiva
id_cnt=0
# valid=1
add_child() {
    local parent=$1
    local child=$2
    children[$parent]="${children[$parent]} $child"
}

add_valori() {
	local parent="$1"
	local valoare="$2"
	valori["$parent"]="${valori["$parent"]} $valoare"
}

push_stiva() {
	local item=$1
	stiva+=( "$item" )
}

pop_stiva() {
	if [ ${#stiva[@]} -gt 0 ]; then
		unset stiva[-1]
	fi
}

print_tree_tags() {
    local node=$1
    local indent=$2
	if [[ "${children[$node]//[[:space:]]/}" == "<>" ]]; then
		echo "${indent}<${node%%#*}/>"
		return
	else
    	echo "${indent}<${node%%#*}>"
	fi

	if [[ ! -z "${valori[$node]//[[:space:]]/}" ]]; then
		echo " $indent${valori[$node]}"
	fi

    for child in ${children[$node]}; do
        print_tree_tags "$child" "  $indent"
    done
	echo "${indent}</${node%%#*}>"
}

print_path_curated() {
	local parent=$1
	for child in ${children[$parent]}; do
		local temp_path=$abs_path
		abs_path+=${parent%%#*}
		abs_path+=/
		if [[ ${child%%#*} == $node ]]; then
			echo "$abs_path${child%%#*}"
			exists=1
		fi
        print_path_curated $child
		abs_path=$temp_path
    done
}
print_path_id() {
	local parent=$1
	for child in ${children[$parent]}; do
		local temp_path=$abs_path
		abs_path+=${parent}
		abs_path+=/
		if [[ ${child%%#*} == $node ]]; then
			echo "$abs_path${child}"
			exists=1
		fi
        print_path_id $child
		abs_path=$temp_path
    done
}

update_tag() {
	local path=$1
	local old_tag=${path##*/}
	local new_tag=$2
	local parent=${path%/*}
	parent=${parent##*/}
	if [[ ! -v children[$old_tag] ]]; then
		echo "Acest element nu exista."
		exit 1
	fi
	children[$parent]="${children[$parent]/$old_tag/$new_tag}"
	children[$new_tag]="${children[$old_tag]}"
	unset "children[$old_tag]"
	valori[$new_tag]="${valori[$old_tag]}"
	unset "valori[$old_tag]"
}

update_value() {
	local path=$1
	local tag=${path##*/}
	local parent=${path%/*}
	parent=${parent##*/}
	local new_val=$2
	local mode=$3
	if [[ ! -v children[$tag] ]]; then
		echo "Acest element nu exista."
		exit 1
	fi
	if [[ $mode == "-c" ]]; then
		valori[$tag]=${valori[$tag]}${new_val}
	elif [[ $mode == "-r" ]]; then
		valori[$tag]=$new_val
	else echo -e "Selectati un mod valid:\nConcatenare: -c\nInlocuire: -r"; exit 1
	fi
}

# add_tag() {
# 	path=$1
# 	child=$2
# 	IFS="/"
# 	read -ra tags <<< $path
# 	for((i=${#tags[@]}-1; i>=1; i--)); do
# 		valid=0
# 		for tag in ${children["${tags[i-1]}"]}; do
# 			if [[ "$tag" == "${tags[i]}" ]]; then
# 				valid=1
# 				break
# 			fi
# 		done
# 		if [[ $valid == 0 ]]; then
# 			return
# 		fi
# 	done
# }

push_stiva "root"

# This marks the beginning of the program
if [[ -z "$1" ]]; then
	echo -e "Nu a fost introdus fisier\nFlaguri valabile:\n-add_tag\n-add_value\n-print_path\n-update_tag\n-update_value"
	exit 1
fi

if [[ ! -f "$1" ]]; then
	echo -e "Fisierul dat nu a fost gasit\nFlaguri valabile:\n-add_tag\n-add_value\n-print_path\n-update_tag\n-update_value"
	exit 1
fi

val=""
while IFS="" read -r linie; do
	for ((i=0; i<${#linie}; i++)); do
		char="${linie:i:1}"
			if [[ "$char" == "<" ]]; then
				if [ ${#stiva[@]} -gt 0 ]; then
					val=$(echo "$val" | tr -s '[:space:]' ' ' | sed 's/^ *//;s/ *$//')
					add_valori "${stiva[-1]}" "$val"
					val=""
				fi
				if [[ "${linie:((i+1)):1}" == "/" ]]; then
					((i+=2))
					close_tag=""
					while [[ "${linie:i:1}" != ">" ]]; do
						close_tag+="${linie:i:1}"
						((i++))
					done
					if [[ "$close_tag" == "${stiva[-1]%%#*}" ]]; then
						pop_stiva
					else echo "Sintaxa nu este valida, tagul ${stiva[-1]%%#*} nu a fost inchis corect."; exit 1
					fi
				else
					self_closing=0
					tag_name=""
					for ((j=i+1; j<${#linie}; j++)); do
						if [[ "${linie:j:1}" == ">" ]]; then
							break
						fi
						if [[ "${linie:j:1}" == "/" ]]; then
							j+=1
							self_closing=1
							break
						fi
						tag_name+="${linie:j:1}"
					done
					i=$j
					(( id_cnt+=1 ))
					tag_name="${tag_name}#${id_cnt}" # caracterul '#' nu poate exista intr-un tagname
					add_child "${stiva[-1]}" "$tag_name"
					push_stiva "$tag_name"
					if [[ $self_closing == 1 ]]; then
						add_child "${stiva[-1]}" "<>"
						pop_stiva
					fi
				fi
			else
				val+="$char"
			fi
	done
done < "$1"


if [[ "$2" == "-add_tag" ]]; then
	if [[ -z "$3" ]]; then
		echo "Introduceti tagname-ul (sau path-ul) cu id si valoarea separate prin spatiu: [tagname#id(sau path) value]"
		exit 1
	fi
	# add_tag "$3" "$4"
	(( id_cnt+=1 ))
	name="${4}#${id_cnt}"
	add_child "${3##*/}" "$name"
	print_tree_tags root ""
elif [[ "$2" == "-add_value" ]]; then
	if [[ -z "$3" ]]; then
		echo "Introduceti tagname-ul (sau path-ul) cu id si valoarea separate prin spatiu: [tagname#id(sau path) value]"
		exit 1
	fi
	add_valori "${3##*/}" "$4"
	print_tree_tags root ""
elif [[ "$2" == "-print_path" ]]; then
	if [[ -z "$3" ]]; then
		echo "Introduceti tagname-ul elementului pentru care vreti sa afisati path-ul de la radacina."
		exit 1
	fi
	abs_path=""
	node=$3
	exists=0
	print_path_curated root
	if [[ $exists == "0" ]]; then
		echo "Tagname-ul introdus nu exista in fisier."
	 	exit 1
	else echo "Path de folosit ca argument pentru celelalte flaguri:"; print_path_id root
	fi
elif [[ "$2" == "-update_tag" ]]; then
	if [[ -z "$3" || -z "$4" ]]; then
		echo "Introduceti path-ul elementului pe care vreti sa il schimbati si noul tag."
		exit 1
	fi
	abs_path=$3
	(( id_cnt+=1 ))
	new_tag=${4}#${id_cnt}
	update_tag $abs_path $new_tag
	print_tree_tags root ""
elif [[ "$2" == "-update_value" ]]; then
	if [[ -z "$3" || -z "$4" || -z "$5" ]]; then
		echo -e "Introduceti path-ul elementului valorii pe care vreti sa il schimbati, modul si noua valoare.\nConcatenare: -c\nInlocuire: -r"
		exit 1
	fi
	abs_path=$3
	mode=$4
	new_val=$5
	update_value $abs_path $new_val $mode
	print_tree_tags root ""
else print_tree_tags root ""; exit 1
fi