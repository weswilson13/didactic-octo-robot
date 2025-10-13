using System.Collections.Generic;
using System.Text;
using System.Linq;
using System.Reflection;

public static class CsvHelper
{
    public static string ListToCsv<T>(List<T> list)
    {
        if (list == null || list.Count == 0)
            return string.Empty;

        var sb = new StringBuilder();
        var properties = typeof(T).GetProperties();  //BindingFlags.Public | BindingFlags.Instance);

        // Header
        sb.AppendLine(string.Join(",", properties.Select(p => p.Name)));

        // Rows
        foreach (var item in list)
        {
            var values = properties.Select(p => (p.GetValue(item, null) ?? "").ToString().Replace("\"", "\"\"")).ToArray();
            sb.AppendLine(string.Join(",", values));
        }

        return sb.ToString();
    }

    public static void SaveCsvToFile(string csvContent, string filePath)
    {
        System.IO.File.WriteAllText(filePath, csvContent);
        Console.WriteLine("CSV file created successfully.");
    }
}

public class ADCsv
{
    public string LastName { get; set; }
    public string FirstName { get; set; }
    public string Username { get; set; }
    public string Email { get; set; }
    public string DoDID { get; set; }
}

public class SWcsv
{
    public string LastName { get; set; }
    public string FirstName { get; set; }
    public string Username { get; set; }
    public string Email { get; set; }
    public string UID { get; set; }
    public string DoDID { get; set; }
}