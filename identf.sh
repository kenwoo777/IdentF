#!/bin/bash


# v.0.3. 20230416. ken woo. copyleft.
# dig out identical files from Left- and Right- sides via sha1sum(or say modified into via any form of unique id; e.g., add size, time).
# ./this_script [options] Left-src-file Right-src-file assigned-left-output assigned-right-output. note the checksums must be sorted.
# items format in the source files: "full-path-filename checksum". e.g., /home/ken/tmp/a.txt c48022dfb82dd8edddd664bd684962d1bfc90db4
# to sort checksums: sed 's/\(.*\) \([a-f0-9A-F]\+$\)/\2 \1/' in.txt | sort -k1,1 | sed 's/\(^[a-f0-9A-F]\+\) \(.*\)/\2 \1/' > out.txt
# or via sha1sum-generated file: sort -k1,1 in.txt | sed -n 's/\(^[a-f0-9A-F]\+\) \(.*\)/\2 \1/p' > out.txt which becomes the source file.
# options: -a, -b, -c, -d.
#     -a: precedes each identical group with a line of sequential number; [[i]].
#     -b: not only -a but also ahead each item the next sequential number.
#     -c: suppose for example, L has 1 line identical to 3 lines in R, then stuffing with additional 2 lines "this-checksum" in L; where
#             is better for 2-way comparison applications/e.g., "meld".
#     -d: enable the output of prefixing "-" of all that are not matched. and it is easy to manually separate later.
# note: 1) if the item format or pattern needs to change, just treat these left-assignment of $left and $right lines.
#       2) checksum identical does not exactly mean file contents identical which must be aware of. conversely exactly diff if diff.
# final release the v.0.2 if luckily no bugs and forbidden myself any new revised ideas.
# v.0.2 revised: minor usage addemdum and added extra info for output and added an option -d since it seems essential.
# example: Left-src & Right-src and Left-output & Right-output are as below by options -abc,
#     Left-src        Right-src        Left-output        Right-output
#
#     /a/b 123        /i/j 456         [[1]]              [[1]]
#     /c/d 456        /k/l 789         [[1]] /c/d 456     [[1]] /i/j 456
#     /e/f 456        /m/n 789         [[2]] /e/f 456     [[2]] 456
#     /g/h 789        /o/p 789
#                                      [[3]]              [[3]]
#                                      [[3]] /g/h 789     [[3]] /k/l 789
#                                      [[4]] 789          [[4]] /m/n 789
#                                      [[5]] 789          [[5]] /o/p 789


IDENTF_VER="Bash 4.3+ script. IDENTF version 0.3"

opt_a="0"
opt_b="0"
opt_c="0"
opt_d="0"
myopts=""
seql=1
seqr=1
cnt=0
isdone="1"
identical_lr=""


while getopts abcd opt; do
    case "$opt" in
        a )
            myopts="${myopts}a"
            opt_a="1";;
        b )
            myopts="${myopts}b"
            opt_a="1"
            opt_b="1";;
        c )
            myopts="${myopts}c"
            opt_c="1";;
        d )
            myopts="${myopts}d"
            opt_d="1";;
        * )
            echo "wrong options"
            exit 1;;
    esac
done

shift $[ $OPTIND - 1 ]

[[ $# -ne 4 ]] && echo "wrong parameters" && exit 1;

exec 3< $1
exec 4< $2
exec 5> $3
exec 6> $4

function auxout() {
    local -n theseq=$1
    echo -n "[[$theseq]] "
    (( theseq=$theseq + 1 ))
    return 0
}

function auxNavL() {
    [[ $opt_d = "1" ]] && echo "-$1" >&5
    return 0
}

function auxNavR() {
    [[ $opt_d = "1" ]] && echo "-$1" >&6
    return 0
}


### ----------
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$( basename -- "${BASH_SOURCE[0]}" )
inipath=$( pwd )
echo -e "\nscript version: $IDENTF_VER\n"
echo "cmd: $SCRIPT_DIR/$SCRIPT_NAME '-$myopts' '$1' '$2' '$3' '$4'"
echo "pwd: $inipath"
echo; echo $( date ); echo;
elapse_time_b=$SECONDS
### ----------


while read -r ctx1 <&3; do
    left=$( sed 's/.* \([0-9a-fA-F]\+$\)/\1/' <<< "$ctx1" )
    [[ ${#left} -eq 0 ]] && continue

    if [[ "$identical_lr" = "$left" ]]; then
        [[ $opt_b = "1" ]] && auxout seql >&5
        echo "$ctx1" >&5
        [[ $opt_c = "1" ]] && (( cnt=$cnt + 1 ))
        continue
    fi

    while read -r ctx2 <&4; do
        isdone="0"
        right=$( sed 's/.* \([0-9a-fA-F]\+$\)/\1/' <<< "$ctx2" )
        [[ ${#right} -eq 0 ]] && continue

        if [[ "$identical_lr" = "$right" ]]; then
            [[ $opt_b = "1" ]] && auxout seqr >&6
            echo "$ctx2" >&6
            if [[ $opt_c = "1" ]]; then
                if [[ $cnt -gt 0 ]]; then
                    (( cnt=$cnt - 1 ))
                else
                    [[ $opt_b = "1" ]] && auxout seql >&5
                    echo "$right" >&5
                fi
            fi
            continue
        else
            [[ $opt_c = "1" ]] && while [[ $cnt -gt 0 ]]; do
                [[ $opt_b = "1" ]] && auxout seqr >&6
                echo "$identical_lr" >&6
                (( cnt=$cnt - 1 ))
            done
            identical_lr=""
        fi

        [[ "$left" < "$right" ]] && $( auxNavL "$ctx1" ) && while read -r ctx1_1 <&3; do
            left=$( sed 's/.* \([0-9a-fA-F]\+$\)/\1/' <<< "$ctx1_1" )
            [[ ${#left} -eq 0 ]] && continue

            [[ "$left" < "$right" ]] && $( auxNavL "$ctx1_1" ) && continue
            ctx1="$ctx1_1"
            break
        done

        [[ "$left" > "$right" ]] && $( auxNavR "$ctx2" ) && continue

        identical_lr="$left"
        if [[ $opt_a = "1" ]]; then

            if [[ $opt_b = "1" ]]; then
                echo -e "\n[[$seql]]" >&5
                auxout seql >&5
                echo "$ctx1" >&5
                echo -e "\n[[$seqr]]" >&6
                auxout seqr >&6
                echo "$ctx2" >&6
            else
                $( echo -e "\n[[$seql]]\n$ctx1" >&5 ) && $( echo -e "\n[[$seql]]\n$ctx2" >&6 ) && (( seql=$seql + 1 ))
            fi

        else $( echo "$ctx1" >&5 ) && $( echo "$ctx2" >&6 )
        fi
        break
    done

    if [[ $isdone = "1" ]]; then
        [[ $opt_d = "1" ]] && $( echo "-$ctx1" >&5 ) || break
    else isdone="1"
    fi

done

# treat the case when L ran out first; as well as the case while L ends up with multiple identical items.
[[ ${#identical_lr} -ne 0 ]] && while read -r ctx2 <&4; do
    right=$( sed 's/.* \([0-9a-fA-F]\+$\)/\1/' <<< "$ctx2" )
    [[ ${#right} -eq 0 ]] && continue

    if [[ "$identical_lr" = "$right" ]]; then
        [[ $opt_b = "1" ]] && auxout seqr >&6
        echo "$ctx2" >&6
        if [[ $opt_c = "1" ]]; then
            if [[ $cnt -gt 0 ]]; then
                (( cnt=$cnt - 1 ))
            else
                [[ $opt_b = "1" ]] && auxout seql >&5
                echo "$right" >&5
            fi
        fi
        continue
    else
        [[ $opt_c = "1" ]] && while [[ $cnt -gt 0 ]]; do
            [[ $opt_b = "1" ]] && auxout seqr >&6
            echo "$identical_lr" >&6
            (( cnt=$cnt - 1 ))
        done
        break
    fi
done
# and for option -d.
[[ $opt_d = "1" ]] && while read -r ctx2 <&4; do
    echo "-$ctx2" >&6
done

exec 3<&-; exec 4<&-; exec 5>&-; exec 6>&-;


### ----------
echo; echo $( date ); echo;
(( time_elapsed=$SECONDS-$elapse_time_b ));
echo -e "\nit took $(( $time_elapsed / 60 )) minute(s) $(( $time_elapsed % 60 )) seconds\n";
### ----------


# end of sh
