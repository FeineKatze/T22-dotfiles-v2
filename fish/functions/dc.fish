function dc
    switch $argv[1]
        case up
            docker compose up -d
        case down
            docker compose down
        case logs
            docker compose logs $argv[2..-1]
        case ps
            docker compose ps
        case '*'
            echo "Not a valid option"
    end
end
