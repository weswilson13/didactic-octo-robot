net use X: /delete
net use Y: /delete
net use Z: /delete

@echo Create new X: drive mapping
net use Z: \\192.168.1.4\NAS01 /persistent:yes 

@echo Create new Y: drive mapping
net use Y: \\192.168.1.4\NAS02 /persistent:yes

@echo Create new Z: drive mapping
net use Y: \\192.168.1.4\NAS03 /persistent:yes
