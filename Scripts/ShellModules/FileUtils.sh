
create_dir_if_not_exists ()
{
    # $1 = dir name

    if ! test -d "$1"
    then
        echo "Creating directory \"$1\" ..."
        mkdir --parents "$1"
    fi
}


delete_file_if_exists ()
{
    if [ -f "$1" ]
    then
        rm -f "$1"
    fi
}

