BEGINFILE {
    c++
}

z[$1]

$1 in a {

    a[$1]=a[$1] FS ($2 ? $2 : "1")
    next
}

{
    for(i=1;i<=c;i++) {
        r = (r ? r FS : "") \
        (i == c ? ($2 ? $2 : "1") : "1")
    }

    a[$1]=r; r=""
    b[++n]=$1
}

ENDFILE {

    for (j in a) {
        if (!(j in z)) {
            a[j]=a[j] FS "1"
        }
    }

    delete z
}

END {

    for (k=1;k<=n;k++) {
        print b[k], a[b[k]]
    }
}