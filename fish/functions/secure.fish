function secure
    set cipher "/run/media/christopher/Transcend/[01] Secure"
    set mount /mnt/Secure

    switch $argv[1]
        case open
            if not mountpoint -q /run/media/christopher/Transcend
                echo "External SSD not mounted!"
                return 1
            end
            gocryptfs -allow_other $cipher $mount
            and echo "Mounted at $mount"
            cd $mount
        case close
            cd ~
            fusermount -u $mount
            and echo Unmounted
        case status
            if mountpoint -q $mount
                echo "Mounted at $mount"
            else
                echo "Not mounted"
            end
        case '*'
            echo "Usage: secure [open|close|status]"
    end
end
