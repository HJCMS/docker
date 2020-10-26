Samba Active Directoy Domain Controller

This Project includes my Personal Samba Active Directory Domain Controller.

Install git/make and clone this project:

	git clone https://github.com/HJCMS/docker-samba-ad-dc.git

	make build

	./first-run-samba.sh ad.hostanme.domain “admin-password“

Open a new Terminal and run:

	docker ps

	docker inspect [ContainerID] or [Name]

to fetch the IP Address of your running Docker Container.

Next step, start my iptables generator and realize the Iptables Rules.

	./generate-iptable.sh

Capture the Docker Interface with tcpdump and ping it from outside:

	tcpdump 'icmp[icmptype] == icmp-echo or icmp[icmptype] == icmp-echoreply' -i docker0 -vvv

Now Check from your Network with ping,nmap or nc.

if it works ...

Change to your Windows Machine and add a route to the docker Network!
If your Windows Machine is a Virtual Machine add the route to your Hypervisor!
Copy or Download my "connection-test-remote.ps1" on it and test the remote Connection.
If the "connection-test-remote.ps1" running with no errors you can use a Domain JOIN.

good luck and have fun ...
