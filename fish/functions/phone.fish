function phone
    set mount /run/media/christopher/Phone

    switch $argv[1]
        case mnt
            if not mountpoint -q $mount
                aft-mtp-mount $mount
            else
                echo "Already mounted"
                return 1
            end
        case umnt
            if mountpoint -q $mount
                fusermount -u $mount
            else
                echo "Nothing mounted"
                return 1
            end
        case '*'
            echo "Only [mnt|umnt]"
    end
end
