Carter Casey

set1.pcap
1. 1503 packets
2. File Transfer Protocol (FTP)
3. FTP seems to send packets in the clear. Given that you can see any information associated with the transfer, you can a) get username and password information and b) recover the files being transferred.
4. There is a secure version of FTP called SFTP (Secure File Transfer Protocol).
5. 67.23.79.113 is the IP address of the server.
6. Username: ihackpineapples, Password: rockyou1
7. Four files were transferred - three jpegs and one text file.
8. The names were BjN-O1hCAAAZbiq.jpg, BvgT9p2IQAEEoHu.jpg, BvzjaN-IQAA3XG7.jpg, and 
smash.txt
9. See submission contents.

set2.pcap

10. 77882 packets
11. There were technically eight username/password pairs, though 7 passwords were paired with just one username. The username chris@digitalinterlude.com was paired with Volrathw69, and the passwords "185 anthony7", "185 allahu", "185 alannah", "185 BASKETBALL", "185 12345d", "185 122333", and "184 yomama1" were paired with the username cisco.
12. I grep'd output from ettercap, looking for the pattern "USER:.*PASS:". This gave me chris username and password. I then ran dsniff on set2.pcap and found the many attempted logins by "cisco".
13. For chris - Protocol: POP3, IP: 75.126.75.131, Domain: digitalinterlude.com, Port: 110.
For cisco - Protocol: telnet, IP: 200.60.17.1, Domain: www.telefonica.com.pe, Port: 23.
14. The username chris@digitalinterlude.com is legitimate, the cisco login attempts resulted in failure.
15. I verified the legitmacy of chris by following the tcp stream of his username and password entry to the server, which were successful. I was then able to see emails he accessed on his account. His successful access to a legitimate server means his username and password were also legitimate.
Similarly, I was able to find the telnet packets cisco was using, and followed each of them to discover a login failed message for each attempted password.
16. They should try to avoid using plain-text protocols like pop - I believe most phone os's give a "security" option to help with this, but they still use underlying plain-text services like pop and imap.  If you feel the need to email on your phone, use it only on trusted/encrypted networks, where there's a low risk of attackers watching the packet transfers.
