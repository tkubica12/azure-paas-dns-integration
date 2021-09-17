# Private DNS integration with various PaaS services
Azure PaaS can be accessed from VNET using Private Endpoint technology or get injected into VNET. As in all those cases FQDN and certificate of service does not change it is important to make sure all internal clients DNS requests get resolved to private IP of the service. Here are few examples of how to integrate this into enteprise solution with hub and spoke topology and custom DNS server using least privilege principles.

# Azure Database - Flexible Server (PostgreSQL, MySQL)
[README](PSQL-flexible-server/README.md)

# Private Endpoint for simple (single endpoint) services such as Azure SQL
TBD

# Private Endpoint for multi-endpoint complex services such as Azure Monitor
TBD

# PowerBI
TBD

# Application Services Environment v3
TBD