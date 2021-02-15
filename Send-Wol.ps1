function Send-Wol {
	#Packet construction reference: 
	#- http://wiki.wireshark.org/WakeOnLAN
	#- http://en.wikipedia.org/wiki/Wake-on-LAN
	#
	#This code is a modified version of: 
	# - http://thepowershellguy.com/blogs/posh/archive/2007/04/01/powershell-wake-on-lan-script.aspx
	
	param (
		[parameter(Mandatory=$true)]
		[ValidateLength(17,17)]
		[ValidatePattern("[0-9|A-F]{2}:[0-9|A-F]{2}:[0-9|A-F]{2}:[0-9|A-F]{2}:[0-9|A-F]{2}:[0-9|A-F]{2}")]
		[String]
		$MacAddress,
		
		[parameter(Mandatory=$false)]
		[int[]]
		$Ports=@(0,7,9)
	)
	
	[int]$MAGICPACKETLENGTH=102 #'Constant' defining total magic packet length.
	[Byte[]]$magicPacket=[Byte[]](,0xFF * $MAGICPACKETLENGTH) #Initialize packet all 0xFF for packet length.
	
	[Byte[]]$byteMac=$MacAddress.Split(":") |% { #Convert the string MacAddress to a byte array (6 bytes).
		[Byte]("0x" + $_) 
	}
	
	#Starting from byte 6 till 101, fill the packet with the MAC address (= 16 times).
	6..($magicPacket.Length - 1) |% {
		$magicPacket[$_]=$byteMac[($_%6)]		
	}
	
	#Setup the UDP client socket.
	[System.Net.Sockets.UdpClient] $UdpClient = new-Object System.Net.Sockets.UdpClient
	foreach ($port in $Ports) {
		$UdpClient.Connect(([System.Net.IPAddress]::Broadcast),$port) #Send packet on each defined port.
		Write-Verbose $("Sending magic packet to {0} port {1}" -f $MacAddress,$port)
		[Void]$UdpClient.Send($magicPacket,$magicPacket.Length) #Don't return the packet length => [void]
	}
	$UdpClient.Close()
}