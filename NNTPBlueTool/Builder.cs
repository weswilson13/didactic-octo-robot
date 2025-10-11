using Microsoft.Extensions.Configuration;
public class Builder
{
    public static IConfiguration BuildConfiguration(string JsonFile)
    {
        var builder = new ConfigurationBuilder();
        builder.SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile(JsonFile, optional: false, reloadOnChange: true);
        return builder.Build();
    }
}