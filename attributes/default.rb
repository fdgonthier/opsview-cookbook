# If this is true, this will let the Opsview package to setup its
# database layer within its packaging.
default[:opsview][:local_mysql] = true

# The MySQL server host.
default[:opsview][:mysql_host] = "localhost"
default[:opsview][:mysql_user] = "root"
default[:opsview][:mysql_pwd] = "root"

# Opsview
default[:opsview][:opsview_pwd] = "root"

# Use 3 for the older version.
default[:opsview][:version] = "4"
