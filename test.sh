#!/bin/bash

declare -A children
declare -A valori
declare -a stiva

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
	if [[ "${valori[$node]//[[:space:]]/}" == "<>" ]]; then
		echo "${indent}<${node}/>"
		return
	else
    	echo "${indent}<${node}>"
	fi

	if [[ ! -z "${valori[$node]//[[:space:]]/}" ]]; then
		echo " $indent${valori[$node]}"
	fi

    for child in ${children[$node]}; do
        print_tree_tags "$child" "  $indent"
    done
	echo "${indent}</${node}>"
}

push_stiva "root"

# This marks the beginning of the program
if [[ -z "$1" ]]; then
	echo "Nu a fost introdus fisier"
	exit 1
fi

if [[ ! -f "$1" ]]; then
	echo "Fisierul dat nu a fost gasit"
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
					while [[ "${linie:i:1}" != ">" ]]; do
						((i++))
					done
					pop_stiva
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

print_tree_tags root ""

print_path() {
	local parent=$1
	for child in ${children[$parent]}; do
		local temp_path=$abs_path
		abs_path+=$parent
		abs_path+=/
		if [[ $child == $node ]]; then
			echo "$abs_path$child"
			exists=1
		fi
        print_path $child
		abs_path=$temp_path
    done
}

if [[ "$2" == "-add_child" ]] || [[ "$2" == "-add_value" ]]; then
	if [[ -z "$3" ]]; then
		echo "Introduceti path-ul si valoarea separate prin spatiu: [t1/t2/.../tn value]"
		exit 1
	fi
elif [[ "$2" == "-print_child" ]] || [[ "$2" == "-print_value" ]]; then
	if [[ -z "$3" ]]; then
		echo "Introduceti path-ul si valoarea separate prin spatiu: [t1/t2/.../tn value]"
		exit 1
	fi
elif [[ "$2" == "-print_path" ]]; then
	if [[ -z "$3" ]]; then
		echo "Introduceti tagname-ul elementului pentru care vreti sa afisati path-ul de la radacina."
		exit 1
	fi
	abs_path=""
	node=$3
	exists=0
	print_path root
	if [[ $exists == "0" ]]; then
		echo "Tagname-ul introdus nu exista in fisier."
	 	exit 1
	fi
else exit 1
fi



