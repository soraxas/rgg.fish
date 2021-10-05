# You can do `abbr rg 'rgg -S'` for easy switching of using rgg as your daily tool

function __vv_list_complete
    for i in (seq (count $__rgg_prev_stored_fnames))
        set -l -- fname $__rgg_prev_stored_fnames[$i]
        set -l -- lnumbers (string split -- '\n' $__rgg_prev_stored_lnumbers[$i])
        for lnum in $lnumbers
            printf -- "$i-$lnum\t%s\n" $fname
        end
    end
end

complete -c vv -x
complete -c vv -x -n '__fish_use_subcommand' -a "(__vv_list_complete)"

# it's ok to define vv here because vv won't work without at least running rgg once
function vv
    if not set -q __rgg_prev_stored_fnames; or not set -q __rgg_prev_stored_lnumbers
        echo "Variables are empty or not set. Have you ran `rgg` yet?"
        return 1
    end

    if set -q -- $argv[1]  # no argunment
        printf 'Usage: vv [FILE_NUMBER[-LINE_NUMBER]]\n'
        printf '\n'
        if not set -q __rgg_prev_stored_fnames[1]; or not set -q __rgg_prev_stored_lnumbers[1]
            echo "Previous rg search has no search results."
            return 
        end

        printf 'Previously stored search results:\n'
        printf '[Arg]\t[LinesNum]\t[Filename]\n'

        # get space necessary to align
        set -l max_linenum_length -1
        for linenum_raw in $__rgg_prev_stored_lnumbers
            set -l linenum (string split '\n' $linenum_raw)
            set -l tmp (math (string length $linenum[1]) '+' (string length $linenum[-1]))
            test $tmp -gt $max_linenum_length
            and set max_linenum_length $tmp
        end

        for i in (seq (count $__rgg_prev_stored_fnames))
            set -l linesnumbers (string split '\n' $__rgg_prev_stored_lnumbers[$i])
            # we will need to +2 later for the two dots, and +1 for a whitespace separator
            set -l line_num_display $linesnumbers[1]".."$linesnumbers[-1]
            printf '%s-XX\t%s%s(%s)\t%s\n' \
                $i \
                $line_num_display \
                (string repeat ' ' -n (math $max_linenum_length '+ 2 + 1 -' (string length $line_num_display))) \
                (count $linesnumbers) \
                $__rgg_prev_stored_fnames[$i]
        end
        return
    end

    # parse argunment
    if not string match -qr -- '^[0-9]+(-[0-9]+)?$' $argv[1]
        echo "Unknown argunment pattern $argv[1]"
        return 1
    end

    set -l split_arg (string split -- '-' $argv[1])
    if test $split_arg[1] -gt (count $__rgg_prev_stored_fnames); or test $split_arg[1] -lt 1
        echo "Given file number $split_arg[1] is out of range (1-"(count $__rgg_prev_stored_fnames)")"
        return 2
    end
    set -q EDITOR
    or set -l EDITOR vim
    $EDITOR "$__rgg_prev_stored_fnames[$split_arg[1]]" "+$split_arg[2]" $argv[2..-1]
end

# main function
function rgg
    set color_code '\e\[[^m]*m'
    function __rgg_process_line

        function __rgg_save_line_numbers
            if test -n "$tmp_lnumbers_list"
                # save previously stored list of line number to the global list
                set -a __rgg_prev_stored_lnumbers (string join -- '\n' $tmp_lnumbers_list)
                set -e tmp_lnumbers_list
            end
        end
        # the following two are presistent in current shell
        set -g __rgg_prev_stored_fnames
        set -g __rgg_prev_stored_lnumbers
        # read from pipeline
        while read -l line
            # strip ANSI colour code
            set -l stripped_line (string replace -ra '\e\[[^m]*m' '' $line)
            # hacky match using output colour

            set -l is_fname
            if string match -rq '^\e\[0m\e\[35m' $line  # hacky way to use colour sequence to determine line type
              set is_fname true
            end

            set -l lnumber (string match -r '^[0-9]+' $stripped_line)
            if test -n "$is_fname" #|| string match -q -r '^\S+' $stripped_line
                # filename
                __rgg_save_line_numbers
                set -a __rgg_prev_stored_fnames $stripped_line
                # starting a new list of line numbers
                set -g tmp_lnumbers_list
                set fname_color_num (set_color cyan)(count $__rgg_prev_stored_fnames)(set_color normal)
                printf (set_color red)'[%s'(set_color red)']'(set_color normal)': ' $fname_color_num
            else if test -n "$lnumber"
                # line numbers
                set -a tmp_lnumbers_list $lnumber
                printf '%s-' $fname_color_num
            # else
            #     # empty line
            #     echo -- ____ $line
            end
            echo -- $line
        end
        # house keeping
        __rgg_save_line_numbers
        set -e fname_color_num
    end

    set rg_args --line-buffered --heading --line-number --color always $argv

    if command -q rga
      rga $rg_args | __rgg_process_line
    else if command -q rga
      rg $rg_args | __rgg_process_line
    else
      echo "No rg installed! (ripgrep)" 1>&2
      return 1
    end

    return
end
