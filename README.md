# DevOps_demo
Demonstration project to manage different DevOps Tools:

- Provide AWS infra with Terraform
- [GIT repository](https://github.com/gonzalo-camino/fssm-inventory-api) with REST API code by [Mulesoft](https://www.mulesoft.com/es/)
[SOAP reference](http://tshirts.demos.mulesoft.com/?wsdl)
- Use Anypoint Trial account
- AWS account (Free) {VPCs, EC2 instances, RDS instances, security groups, routing tables, etc}
--VPCs:
1. Linux EC2 instance (+ Mule Runtime)
2. MySQL RDS service || EC2 instance with MySQL installed. [Query](https://github.com/gonzalo-camino/fssm-inventory-api/blob/main/src/main/resources/db/script.sql)

- Create an Ansible script // Note: don’t use the Mule Kernel (open source)
[LINK](https://www.mulesoft.com/lp/dl/mule-esb-enterprise)
- Mule enterprise standalone Runtime (trial) on your EC2/VPC1
- Manually build and deploy the API setting DB parameters (host, port, database, username, password) to the Mule Runtime.

```
a. To test the API, you can use the API Console embedded. Once your mule API is running, access it on this URL:
http://<YOUR_IP>:<YOUR_PORT>/console
b. You can enter any value on client_id and client_secret to do the calls; they are declared on the API spec,
but given that the API is not managed on API Manager, there is no security mechanism in place yet.
```

#OPTIONALLY... * Choose 1 item to perform along with the mandatory part.

- Create a Terraform script to automatically generate all the required infrastructure for this Demo :heavy_check_mark:
- Use a CI/CD pipeline that deploys the Inventory REST API developed by MuleSoft Solution Engineer, from Github’s source code to your EC2 instance on VPC1
 (You don’t need to change the source code of the mule application at all to make it work.) :heavy_check_mark:
- Extend the current solution to support a multi-region environment: You can assume a scenario in which a new DB backend service needs to be included in the solution,
but it is now hosted on a new VPC3 on a different AWS region (i.e. you have the VPC1 and VPC2 on us-east-1 and the VPC3 on us-east-2).
It is not necessary to implement it, just to explain in detail the options available, pros and cons for each one, and what would you recommend.

### 🔗 Author Links
[![linkedin](https://img.shields.io/badge/linkedin-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/natt-forclaz/)
[![github](https://img.shields.io/github/followers/in-natt?label=in-natt&style=social)](https://github.com/in-natt)

### Used By

This project is developed and used by:

- Mulesoft