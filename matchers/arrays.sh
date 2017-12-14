arrayeq() {
    # if the number of args is impar, then the two arras can't possibly have the
    # same number of elements
    assert equal 0 $(( $# % 2 ))

    local ai=0
    local bi=$(($# / 2 ))
    local args=( "$@" )
    while (( bi < $# )); do
        assert equal "${args[$ai]}" "${args[$bi]}"

        (( ai += 1 ))
        (( bi += 1 ))
    done
}
