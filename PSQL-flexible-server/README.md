# Azure Database - Flexible Server (PostgreSQL, MySQL)
Use Terraform to deploy hub and spoke environment, DNS, VMs for testing and other components:
- Hub and spoke networks
- Custom Azure DNS zone mycustomname.postgres.database.azure.com created in Hub - this zone must be mapped to both hub and spoke network (this seems to be currently required for service creation - API call to create DB will check this and fail if it is not true)
- Custom DNS server in hub
- Custom least privilege role for spoke users (allow JOIN operation to DNS) and SP account to test things out
- VM in spoke to test DNS resolution - access it via serial console in portal (or add public IP and modify NSG)

# Check how DNS works
Connect to appvm and make sure DNS works properly.

```
tomas@appvm:~$ dig psql1.postgres.database.azure.com

; <<>> DiG 9.11.3-1ubuntu1.15-Ubuntu <<>> psql1.postgres.database.azure.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 11292
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;psql1.postgres.database.azure.com. IN A

;; ANSWER SECTION:
psql1.postgres.database.azure.com. 30 IN CNAME ee7d7d84c274.mycustomname.postgres.database.azure.com.
ee7d7d84c274.mycustomname.postgres.database.azure.com. 29 IN A 10.1.0.5

;; Query time: 16 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Thu Sep 16 11:31:16 UTC 2021
;; MSG SIZE  rcvd: 122

tomas@appvm:~$ dig psql2.postgres.database.azure.com

; <<>> DiG 9.11.3-1ubuntu1.15-Ubuntu <<>> psql2.postgres.database.azure.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 31948
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;psql2.postgres.database.azure.com. IN A

;; ANSWER SECTION:
psql2.postgres.database.azure.com. 30 IN CNAME abaf971a29f4.mycustomname.postgres.database.azure.com.
abaf971a29f4.mycustomname.postgres.database.azure.com. 29 IN A 10.1.0.4

;; Query time: 13 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Thu Sep 16 11:31:41 UTC 2021
;; MSG SIZE  rcvd: 122
```

# RBAC test
Simulate spoke user creating resource using CLI to make sure least privilege to DNS zones is working fine.

## Get service principal
```bash
export password=$(terraform output -raw client_secret)
export spid=$(terraform output -raw client_id)
export paasSubnetId=$(terraform output -raw paasSubnetId)
export dnsId=$(terraform output -raw dnsId)
```

## Login to Azure with SP
```
az login --service-principal --username $spid --password $password --tenant microsoft.com
```

## Create PostgreSQL Flexible Server
```
az postgres flexible-server create -g spoke-rg -n psqlnew --private-dns-zone $dnsId --sku-name Standard_B1ms --subnet $paasSubnetId --tier Burstable -u tomas -p Azure12345678
```

## Delete PostgreSQL Flexible Server
```
az postgres flexible-server delete -g spoke-rg -n psqlnew
```