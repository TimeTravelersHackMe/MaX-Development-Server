<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="MySql.Data.MySqlClient" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>ASP and MySQL Test Page</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />

<script runat="server">
private void Page_Load(Object sender, EventArgs e)
{
string connectionString = "Server=localhost;Database={DATABASE_NAME};User ID={DATABASE_USER};Password={DATABASE_PASSWORD};Pooling=false;";
MySqlConnection dbcon = new MySqlConnection(connectionString);
dbcon.Open();

MySqlDataAdapter adapter = new MySqlDataAdapter("SELECT * FROM test", dbcon);
DataSet ds = new DataSet();
adapter.Fill(ds, "result");

dbcon.Close();
dbcon = null;

SampleControl.DataSource = ds.Tables["result"];
SampleControl.DataBind();
}
</script>

</head>

<body>
<h1>Testing Sample Database</h1>
<asp:DataGrid runat="server" id="SampleControl" />
</body>

</html>
