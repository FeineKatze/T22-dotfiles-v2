function updatedb-gen
    set d ~/.config/updatedb
    set paths (grep -vE '^\s*(#|$)' $d/prunepaths.txt | string join ' ')
    set names (grep -vE '^\s*(#|$)' $d/prunenames.txt | string join ' ')
    set fs (grep -vE '^\s*(#|$)' $d/prunefs.txt | string join ' ')
    printf 'PRUNE_BIND_MOUNTS = "yes"\nPRUNEFS = "%s"\nPRUNENAMES = "%s"\nPRUNEPATHS = "%s"\n' "$fs" "$names" "$paths" | sudo tee /etc/updatedb.conf >/dev/null
end
