#!/bin/bash
# third iteration of my todo list manager
# built to run with options rather than a menu

# list storage directory
todo_dir="$HOME/.todo3"

# formatting and various
bold="\e[01;37m"
rst="\e[m"

# checks for storage directory
RunInitial() {

    # check for existence of storage directory
    # and make one if not available
    if [ ! -d $todo_dir ]; then
        mkdir $todo_dir
        touch "$todo_dir/default"
    fi

}

# show usage and exit
DisplayUsage() {

    printf "\n${bold}USAGE${rst}
./todo3.sh [option]

${bold}OPTIONS\t\t\tSHORT\t\tDESCRIPTION${rst}
show-lists\t\t-sl\t\tDisplay all todo lists.
show-entries [list]\t-se [list]\tDisplay entries in a todo list.
delete-entry [list]\t-de [list]\tDelete an entry from a todo list.
add-entry [list]\t-ae [list]\tAdd a new entry to a todo list.
create-list [list]\t-cl [list]\tCreate a new todo list.
delete-list [list]\t-dl [list]\tDeletes an existing todo list.\n\n"

    exit 1

}

# show all todo lists
DisplayLists() {

    printf "${bold}LIST NAME [entries]${rst}\n"

    # iterate through todo_dir and show contents
    for list in $todo_dir/*; do 
        entries=$(wc -l $list | awk '{print $1}')
        list_name=$(echo $list | awk -F'/' '{print $5}')

        printf "$list_name [$entries]\n"

    done

}

# validate a passed list
ValidateList() {

    # assign valid_list to 0 until list_name validated
    valid_list=0

    # check for a valid list name
    for list in $todo_dir/*; do
        if [[ $1 == $(echo $list | awk -F'/' '{print $5}') ]]; then
            valid_list=1
        fi
    done

    # exit if list_name couldn't be validated
    if [[ $valid_list -ne 1 ]]; then
        printf "ERROR: Invalid list specified.\n"
        DisplayUsage
    fi


}

# show contents of a todo list
DisplayEntries() {

    # assign passed argument to list_name
    list_name=$1

    ValidateList $list_name

    # create path to list
    file_path="$todo_dir/$list_name"

    # if the list is empty then display message and exit
    if [[ ! -s $file_path ]]; then
        printf "List is empty.\n"
        DisplayUsage

    fi
    
    printf "${bold}Date Added\tList Entry${rst}\n"

    # read the specified file and print entries
    while IFS='' read -r line || [[ -n "$line" ]]; do

        printf "$line\n"

    done < $file_path
 
}

# delete an entry from a todo list
DeleteEntry() {

    # assign passed argument to list_name
    list_name=$1

    # displays line numbers
    line_num=1

    ValidateList $list_name

    # create path to list
    file_path="$todo_dir/$list_name"

    printf "${bold}Line\tDate Added\tList Entry${rst}\n"

    # read the specified file and print entries
    while IFS='' read -r line || [[ -n "$line" ]]; do
                
        printf "$line_num\t$line\n"

        # increment line number
        line_num=$(($line_num+1))

    done < $file_path

    printf "\nEnter a line number to delete (q to quit): "
    read delete_line

    # quit if q is entered
    if [[ $delete_line == "q" ]]; then
        printf "\nExiting.\n"
        exit
    fi

    printf "\n$(sed -n ${delete_line}p ${file_path})
Delete the preceding line? (y for yes): "

    read user_confirm

    # check if user_confirm is not y
    if [[ $user_confirm != "y" ]]; then
        printf "\nNo deletion occured. Exiting.\n"
        exit

    else
        # delete specified line
        sed -i "$delete_line"'d' "$file_path" 
        printf "\nLine deleted. Exiting.\n"
        exit

    fi

    
}

# add an entry to a todo list
AddEntry() {
    
    # assign passed argument to list_name
    list_name=$1

    ValidateList $list_name

    # format date for new entry
    date="$(date +"%m-%d-%y")"

    # create path to list
    file_path="$todo_dir/$list_name"

    printf "Enter your new entry (q to quit): "

    read new_entry

    # quit if q is entered
    if [[ "$new_entry" == "q" ]]; then
        printf "\nExiting.\n"
        exit
    fi
    
    printf "\n$date\t$new_entry
Add the preceding line to $list_name? (y for yes): "

    read user_confirm

    # check if user_confirm is not y
    if [[ $user_confirm != "y" ]]; then
        printf "\nEntry not added to '$list_name'. Exiting.\n"
        exit

    else
        # append new entry to list_name
        printf "$date\t$new_entry\n" >> $file_path
        printf "\nYour new entry has been added to '$list_name'. Exiting.\n"

    fi

}

# create a new todo list
CreateList () {

    # assign passed argument to new_list
    new_list=$1 

    # assign existing_list to 0 until check occurs
    existing_list=0

    # check for duplicate of new_list
    for list in $todo_dir/*; do
        if [[ $new_list == $(echo $list | awk -F'/' '{print $5}') ]]; then
            existing_list=1
        fi
    done

    # if existing_list is 1 then exit, otherwise make the new list
    if [[ $existing_list -eq 1 ]]; then
        printf "ERROR: List exists.\n"
        DisplayUsage

    else
        touch "$todo_dir/$new_list"
        printf "Todo list '$new_list' created. Exiting.\n"
    fi

}

# delete an existing todo list
DeleteList () {

    # assign passed argument to delete_list
    delete_list=$1

    ValidateList $delete_list

    printf "Delete list '$delete_list'? All entries will be lost. (y for yes): "

    read user_confirm

    # if user_confirm is not y then exit without deleting
    if [[ $user_confirm != "y" ]]; then
        printf "\nNo list deletion occurred. Exiting.\n"
        exit

    else
        rm "$todo_dir/$delete_list"
        printf "\nList '$delete_list' deleted. Exiting.\n"

    fi

}

##################################
###        SCRIPT START        ###
##################################

RunInitial

# check for options
if [ -z $1 ]; then
    DisplayUsage

# process passed argument 'show-lists'
# USAGE: ./todo3.sh show-lists or ./todo3.sh -s
elif [[ $1 == "show-lists" || $1 == "-sl" ]]; then
    DisplayLists

# process passed argument 'show-entries'
# USAGE: ./todo3.sh show-entries [list] or ./todo3.sh -e [list]
elif [[ $1 == "show-entries" || $1 == "-se" ]]; then
    # checks for empty second argument
    if [ -z $2 ]; then
        printf "ERROR: No todo list specified.\n"
        DisplayUsage
    fi

    # pass the 2nd argument to DisplayEntries
    DisplayEntries $2

# process passed argument 'delete-entry'
# USAGE: ./todo3.sh delete-entry [list] or ./todo3.sh -de [list]
elif [[ $1 == "delete-entry" || $1 == "-de" ]]; then
    # checks for empty second argument
    if [ -z $2 ]; then
        printf "ERROR: No todo list specified.\n"
        DisplayUsage
    fi

    # pass the 2nd argument to DeleteEntry()
    DeleteEntry $2

# process passed argument 'add-entry'
# USAGE: ./todo3.sh add-entry [list] or ./todo3 -ae [list]
elif [[ $1 == "add-entry" || $1 == "-ae" ]]; then
    # checks for empty second argument
    if [ -z $2 ]; then
        printf "ERROR: No todo list specified.\n"
        DisplayUsage
    fi

    # pass the 2nd argument to AddEntry()
    AddEntry $2

# process passed argument 'create-list'
# USAGE ./todo3.sh create-list [list] or ./todo3 -cl [list]
elif [[ $1 == "create-list" || $1 == "-cl" ]]; then
    # checks for empty second argument
    if [ -z $2 ]; then
        printf "ERROR: No new todo list specified.\n"
        DisplayUsage
    fi

    #pass the 2nd argument to CreateList()
    CreateList $2

# process passed argument 'delete-list'
# USAGE ./todo3.sh delete-list [list] or ./todo3 -dl [list]
elif [[ $1 == "delete-list" || $1 == "-dl" ]]; then
    # checks for empty second argument
    if [ -z $2 ]; then
        printf "ERROR: No todo list specified.\n"
        DisplayUsage
    fi

    #pass the 2nd argument to DeleteList()
    DeleteList $2

# process passed invalid arguments
else
    printf "ERROR: Invalid option specified.\n"
    DisplayUsage

fi
