Carter Casey

I believe all portions of the assignment have been implemented correctly.

I did not collaborate on or discuss this project with anyone, though I used a script from stackoverflow to doubly check if a valid credit card had been passed in the clear.

I spent somewhere between six and eight hours on this project (I think).

Extra questions:
	Using regexes often gives a necessary warning flag, but aren't always sufficient to demonstrate real danger.  Before using the Luhn algorithm to check if numbers found by my credit card regex were valid, I would get many hits of numbers that just happened to have the right number of digits (and started with the right numbers) to fit my regexes. The regexes I use to find shellcode certainly aren't airtight - I check for repeated hex representations and the strings bin and sh, with the intuition that people will need those to run remote commands. It would require deeper checking to truly validate these issues (hence my going to find the Luhn algorithm).
	
	If I had spare time in the future, I could attempt to contact an appropriate server to verify that what I'd found was really a credit card (I assume this is possible). I could also conceivably parse the possible shellcode with more rigorous techniques - for instance, check if there is a valid command that could be executed.