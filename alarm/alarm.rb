#!/usr/bin/env ruby
require "packetfu"
require "base64"

# The interface to use when parsing
INTERFACE = "en1"

# regex for AmEx cards
AMEX_REGEX = /\D\d{3}(?:\s|-)?\d{6}(?:\s|-)?\d{5}\D/
# regex for Discover cards
DISC_REGEX = /\D6011(?:\s|-)?\d{4}(?:\s|-)?\d{4}(?:\s|-)?\d{4}\D/
# regex for Master cards
MAST_REGEX = /\D5\d{3}(?:\s|-)?\d{4}(?:\s|-)?\d{4}(?:\s|-)?\d{4}\D/
# regex for Visa cards
VISA_REGEX = /\D4\d{3}(?:\s|-)?\d{4}(?:\s|-)?\d{4}(?:\s|-)?\d{4}\D/

CARDS = [AMEX_REGEX, DISC_REGEX, MAST_REGEX, VISA_REGEX]

# regex for parsing server log lines
LOG_REGEX = /((?:\d{1,3}\.){3,5}\d{1,3}) (\S+) (\S+) (\[.*\]) (\".*\") (\d+) (\d+) (\".*\")? (\".*\")?/

# regex for attempting to catch shellcode
# -- require three repeats as a baseline for repetition
SHELL_REGEX = /((?:.?[\\x%]+[0-9a-fA-F]{2}){3,})/
# regex for common terms used with remote commands
REMOTE_REGEX = /\b(?:(?:bin)|(?:sh))\b/

# Check if card passes the Luhn test
#
# arguments:
# card_str:: The credit card as a string
#
# authorship: This function was taken (then refactored) from
# http://stackoverflow.com/a/19014547
def validateCard(card_str)
	card_str = card_str.gsub(/[^0-9]/, "")

	digits = card_str.split("").map(&:to_i)
	checksum = digits.pop # chop off last digit, store as checksum
	digits << 0 # Add back in a zero for balanced calculations

	sum = 0
	digits.each_slice 2 do |pair|
		double = pair.first * 2
		sum += (double >= 10) ? (double % 10 + 1) : double
		sum += pair.last
	end

	(sum * 9) % 10 == checksum 

end


# Checks for non-printable characters and replaces them
# 
# arguments:
# str:: the string to be parsed
def parseAscii str
	str.chars.map { |c| c !~ /[[:print:]]/ ? "0x" + c.ord.to_s : c}.join
end

# Checks for NULL or XMAS scans in packet
#
# arguments:
# packet:: the packet to be checked
def checkScan packet
	if packet.is_tcp?
		if packet.tcp_flags.to_i == 0 # No flags on
			return "NULL"
		elsif packet.tcp_flags.to_i == 41 # FIN, PSH, URG flags all on
			return "XMAS"
		end
	end
	nil
end

# Checks for plaintext credit card numbers
#
# arguments:
# packet:: packet to be parsed
def checkCard packet
	for card_regex in CARDS
		if packet.payload.match card_regex
			$stderr.puts "MATCH!"
			if ((packet.payload.scan card_regex).any? { |c| validateCard c })
				return true
			end
		end
	end
	false
end

# Reads from the specificed interface and checks for certain incidents
# 
# arguments::
# iface:: The interface on which to listen for incidents
# 
# incidents detected:
# NULL scan:: An nmap scanning attack
# XMAS scan:: An nmap scanning attack
# Card leak:: Credit cards leaked in plain text
def liveCapture iface
	cap = PacketFu::Capture.new(:start => true, :iface => iface, :promisc => true)
	count = 1

	cap.stream.each do |p|
		pkt = PacketFu::Packet.parse p
		payload = parseAscii pkt.payload
		if (scan_type = checkScan pkt)
			puts "#{count}. ALERT: #{scan_type} is detected from #{pkt.ip_saddr} (#{pkt.proto.last}) (#{payload})!"
			count += 1
		end
		if checkCard pkt
			puts "#{count}. ALERT: Credit card leaked in the clear from #{pkt.ip_saddr} (HTTP) (#{payload})!"
			count += 1
		end
	end

end

# Reads through the specified server file and checks for certain incidents
#
# arguments:
# log_name:: name of the server log to parse
#
# incidents:
# NMAP scan:: Any scan from the nmap tool
# HTTP errors:: Any error in the 400 range
# Shellcode:: Attempt to abuse buffer overflow
def parseLog log_name
	log_file = File.open(log_name, "r")
	count = 1
	for line in log_file
		fields = (line.scan LOG_REGEX)[0]
		source_addr = fields[0]
		payload = fields[4]
		http_code = fields[5].to_i
		# Check if nmap is named
		if line =~ /\bnmap\b/i
			puts "#{count}. ALERT: NMAP scan is detected from #{source_addr} (HTTP) (#{payload})!"
			count += 1
		end
		# Check whether code was in error range (400s)
		if http_code / 100 == 4
			puts "#{count}. ALERT: HTTP error is detected from #{source_addr} (HTTP) (#{payload})!"
			count += 1
		end
		# Check both that a shellcode pattern is found, and that a command is attempted
		if payload =~ SHELL_REGEX and payload =~ REMOTE_REGEX
			puts "#{count}. ALERT: Shellcode attack is detected from #{source_addr} (HTTP) (#{payload})!"
			count += 1
		end
	end
	log_file.close
end

# Parse command line, check server log validity
if ARGV.length == 2
	if ARGV[0] == "-r"
		log = ARGV[1]
		begin
			parseLog log
		rescue Errno::ENOENT
			$stderr.puts "'#{log}': no such file or directory"
			exit 1
		end
	else
		$stderr.puts "Usage: sudo ruby alarm.rb [-r <web_server_log>]"
		exit 1
	end
elsif ARGV.length == 0
	liveCapture INTERFACE
else
	$stderr.puts "Usage: sudo ruby alarm.rb [-r <web_server_log>]"
	exit 1
end
