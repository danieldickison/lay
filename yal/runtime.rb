HOSTNAME = `hostname`.strip

if HOSTNAME =~ /show-server/
    PRODUCTION = true
    DEVELOPMENT = false
else
    PRODUCTION = false
    DEVELOPMENT = true
end

if DEVELOPMENT
    if HOSTNAME == "clash"
        JOE_DEVELOPMENT    = true
        DANIEL_DEVELOPMENT = false
    else
        JOE_DEVELOPMENT    = false
        DANIEL_DEVELOPMENT = true
    end
end
