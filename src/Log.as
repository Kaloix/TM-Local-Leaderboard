namespace LocalLeaderboard
{

void LogDebug(const string&in message)
{
    Log(message, LogLevel::DEBUG);
}

void LogInfo(const string&in message)
{
    Log(message, LogLevel::INFO);
}

void LogWarning(const string&in message)
{
    Log(message, LogLevel::WARNING);
}

void LogError(const string&in message)
{
    Log(message, LogLevel::ERROR);
}

void Log(const string&in message, LogLevel level = LogLevel::INFO)
{
    auto msg = "[" + LogLevelToString(level) + "] " + message;

    switch (level)
    {
        case LogLevel::DEBUG:
            if (!settingShowDebugInfo)
            {
                return;
            }

            print(msg);
            break;
        case LogLevel::INFO:
            print(msg);
            break;
        case LogLevel::WARNING:
            warn(msg);
            break;
        case LogLevel::ERROR:
            UI::ShowNotification(Meta::ExecutingPlugin().Name, message, vec4(1, 0, 0, 1), 5000);
            error(msg);
            break;
    }
}

enum LogLevel
{
    DEBUG,
    INFO,
    WARNING,
    ERROR,
}

string LogLevelToString(LogLevel level)
{
    switch (level)
    {
        case LogLevel::DEBUG:
            return "DEBUG";
        case LogLevel::INFO:
            return "INFO";
        case LogLevel::WARNING:
            return "WARNING";
        case LogLevel::ERROR:
            return "ERROR";
        default:
            return "UNKNOWN";
    }
}

}