# ##############################################################
# # Description: Query the user for a file name. We assume     #
# # it must be a complete path name since we cannot anticipate #
# # where QTSPIM will expect a local file. The routine (OFile) #
# # will read in the filename and try to open it. If not       #
# # it will continue to ask the user for a valid filename.     #
# # Once successful, the file pointer will be passed back to   #
# # the calling routine. Prints 9x9 Sudoku puzzle. Checks      #
# # each row, column and box for valid sudoku algorithm.       #
# # Author: Cristina S. Alonso                                 #
# # Date: March 8, 2019                                        #
# # Copyright: This code is property of Miss Cristina          #
# # S. Alonso, written by Miss Cristina S. Alonso for          #
# # the sole use of no one.                                    #
# # Distrubution is not authorized.                            #
################################################################
        .data
Hello:  .asciiz "Hello,Enter a file name: \n"
        .align 2
NoFile: .asciiz "Error encountered, file did not open\n"
OkFile: .asciiz "File was opened\n"
Filen:  .space 256 # Set aside 256 Characters
MSG1:   .asciiz "Valid Sudoku Puzzle"
MSG2:   .asciiz "Invalid Sudoku Puzzle"
UNDER:	.asciiz "|-|-|-|-|-|-|-|-|-|\n"
BAR:	  .byte	'|'
EOL:    .byte '\n'
        .align 2
digits: .asciiz "123456789"
        .align 2
sudoku: .space 164
NullCh: .word 0 # Just in case we need a null character
# After the puzzle.
        .align 2 # Align on full word boundary
        .text
        .globl main
main:
# ###################################################################
# Save the return address ($ra) and call the Open File function(Ofile).
#####################################################################

  addiu $sp,$sp,-4 # Get space from the stack
  sw $ra,0($sp) # Store return address on stack
  la $a0,Filen # Load $a0 (parameter) with address to
                # store filename.
  jal OFile # Call Open File

# #####################################################################
# # Save the file pointer in saved register $s1. Restore the return #
# # address and stack pointer. #
#######################################################################

  move $s1,$v0 # Save Filename pointer to $s1
  lw $ra,0($sp) # Restore return address
  addiu $sp,$sp,4 # Restore stack pointer
  la $a0,OkFile # Get ready to print success message
  li $v0,4 # Tell syscall to print a string
  syscall

  li $v0,14
  move $a0,$s1 # pass file pointer
  la $a1,sudoku # Where to store the data
  li $a2,164 # Size of buffer to read in
  syscall
  li $v0,4
  la $a0,sudoku
  syscall

  la $a0,sudoku # Load address of sudoku in $a0
  addiu		$sp,$sp,-4	# Get stack space
  sw		$ra,0($sp)	# Store return address
  jal		PRTPZL		# Call PRTPZL
  lw		$ra,0($sp)	# Restore return address
  addiu		$sp,$sp,4	# Restore stack space

  la $a0,sudoku # Load address of sudoku in $a0
  la $a1,digits # Load address of digits in $a1
  addiu		$sp,$sp,-4	# Get stack space
  sw		$ra,0($sp)	# Store return address
  jal		GETROW		# Call GETROW
  lw		$ra,0($sp)	# Restore return address
  addiu		$sp,$sp,4	# Restore stack space

  beq $v0,$zero,END # if boolean == 0, then false

  la $a0,sudoku # Load address of sudoku in $a0
  la $a1,digits # Load address of digits in $a1
  addiu		$sp,$sp,-4	# Get stack space
  sw		$ra,0($sp)	# Store return address
  jal		GETCOL		# Call GETCOL
  lw		$ra,0($sp)	# Restore return address
  addiu		$sp,$sp,4	# Restore stack space

  beq $v0,$zero,END # if boolean == 0, then false

  la $a0,sudoku # Load address of sudoku in $a0
  la $a1,digits # Load address of digits in $a1
  addiu		$sp,$sp,-4	# Get stack space
  sw		$ra,0($sp)	# Store return address
  jal		GETBOX		# Call GETBOX
  lw		$ra,0($sp)	# Restore return address
  addiu		$sp,$sp,4	# Restore stack space

  beq $v0,$zero,END # if boolean == 0, then false

  li	$v0,11		# Tell syscall to print a character
	lb	$a0,EOL		# Print end of line
	syscall
  li $v0,4 # print string
  la $a0,MSG1 # valid message
  syscall

  jr	$ra			# Stop Program

END: # false
  li	$v0,11		# Tell syscall to print a character
  lb	$a0,EOL		# Print end of line
  syscall
  li $v0,4 # print string
  la $a0,MSG2 # invalid message
  syscall

  jr $ra # Stop Program

# ####################################################################
# Function to read from standard input a filename and open a file.
#
# Send the address of where to store the filename in $a0.
#
# Return the file pointer in $v0.
#
########################################################################

OFile:
  move $t1,$a0 # Move address of where we want the
                # file name to go to

Again: # $t1
  li $v0,4 # Tell syscall to print a string
  la $a0,Hello # Load address of string to print
  syscall # Print string
  move $a0,$t1 # Load $a0 with the address of where we want
  # the
  # Filename to go.
  li $a1,264 # Load max size of string
  li $v0,8 # Tell syscall to read a string
  syscall # Read a string

# #####################################################################
# # Ok, we have read in a string.. Now we want to scan the string and #
# # find a linefeed (the number 10 or hex A) and replace it with binary#
# # zeros which is a null character. #
#
########################################################################

  la $t2,EOL # EOL is the character after the filename
              # declaration.
  sub $t3,$t2,$t1 # Subtract the address of the EOL from
                    # the address of the Filen to get the length
  move $t4,$t1 # Put address of filename in $t4

GetB:
  lb $t5,0($t4) # load byte into $t5
  li $s5,10 # Load line feed in $s1
  beq $t5,$s5,Done # Go to Done when line feed found
  addiu $t4,$t4,1 # Get next byte
  j GetB

Done:
  li $s5,0 # Load zero (null character) into $s1
  sb $s5,0($t4) # Replace the line feed with null character

# ######################################################################
# # Try to open the file, If it works move the file pointer to $v0 #
# # and return. #
# # If not, go back and read in another filename.
########################################################################

  li $v0,13 # tell syscall to open a file
  move $a0,$t1 # Move address of file in $a0
  li $a1,0 # Open for reading
  li $a2,0 # No purpose
  syscall # Open file
  move $s6,$v0
  ble $s6,$zero,Again # Bad file, try it again.
  move $v0,$s6
  jr $ra

PRTPZL:
	move	$s0,$a0		# Preserve parameter
	li	$s1,9		# Set up Counter
  li	$v0,11		# Tell syscall to print a character
	lb	$a0,EOL		# Print end of line
	syscall
  j MIDDLE
TOP:
  beq	$s1,$zero,DNPZL	# Branch to DNPZL if counter is zero
	li	$v0,4		# Tell syscal to print a string
	la	$a0,UNDER	# Print underscore
	syscall
MIDDLE:
	li	$v0,11		# Print vertical bar
	lb	$a0,BAR		# Load the BAR
	syscall
	li	$v0,11		# Tell syscall to print a character
	lb	$a0,0($s0)	# Print first number in row
	syscall
	li	$v0,11		# Print vertical bar
	lb	$a0,BAR		# Load the BAR
	syscall
	li	$v0,11		# Tell syscall to load a byte
	lb	$a0,2($s0)	# Print second number in row
	syscall
	li	$v0,11		# Print vertical bar
	lb	$a0,BAR		# Load the BAR
	syscall
	li	$v0,11		# Tell syscall to print a character
	lb	$a0,4($s0)	# Print third number in row
	syscall
	li	$v0,11		# Tell syscall to print a character
	lb	$a0,BAR		# Load the BAR
	syscall
  li	$v0,11		# Tell syscall to print a character
  lb	$a0,6($s0)	# Print fourth number in row
  syscall
  li	$v0,11		# Tell syscall to print a character
  lb	$a0,BAR		# Load the BAR
  syscall
  li	$v0,11		# Tell syscall to print a character
  lb	$a0,8($s0)	# Print fifth number in row
  syscall
  li	$v0,11		# Tell syscall to print a character
  lb	$a0,BAR		# Load the BAR
  syscall
  li	$v0,11		# Tell syscall to print a character
  lb	$a0,10($s0)	# Print sixth number in row
  syscall
  li	$v0,11		# Tell syscall to print a character
  lb	$a0,BAR		# Load the BAR
  syscall
  li	$v0,11		# Tell syscall to print a character
  lb	$a0,12($s0)	# Print seventh number in row
  syscall
  li	$v0,11		# Tell syscall to print a character
  lb	$a0,BAR		# Load the BAR
  syscall
  li	$v0,11		# Tell syscall to print a character
  lb	$a0,14($s0)	# Print eighth number in row
  syscall
  li	$v0,11		# Tell syscall to print a character
  lb	$a0,BAR		# Load the BAR
  syscall
  li	$v0,11		# Tell syscall to print a character
  lb	$a0,16($s0)	# Print nineth number in row
  syscall
  li	$v0,11		# Tell syscall to print a character
  lb	$a0,BAR		# Load the BAR
  syscall
	li	$v0,11		# Tell syscall to print a character
	lb	$a0,EOL		# Print end of line
	syscall
	addiu	$s0,$s0,18	# Get next row
	addiu	$s1,$s1,-1	# Subtract from counter
	j	TOP
DNPZL:
	jr	$ra

GETROW:
  move $s0,$a0 # Preserve sudoku
  move $t0,$s0 # Move sudoku to temporary
  move $s1,$a1 # Preserve digits
  move $t1,$s1 # Move digits to temporary
  lb $s2,($t1) # Get digits[0]
  li $s4,1 # Set boolean (digit found in one row) to true
  li $s5,1 # Set boolean (digit found in all rows) to true
  li $t4,0 # Counter for total number of rows
NEXTROWLP: # Loops through each row in puzzle
  beq $t4,9,NEXTROWDN # Branch to NEXTROWDN if counter is 9
SRCHROWLP: # Loops digits to pick one digit
  beq $s2,$zero,SRCHROWDN # Branch if string terminates
  li $t3,9 # Counter for number of elements in row (e.g. columns)
ROWLP: # Loops one row to search for digit
  beq	$t3,$zero,ROWDN	# Branch to ROWDN if counter is 0
  lb	$a0,0($t0)	# load character to look for in row
  seq $t7,$a0,$s2 # compare row element and digit
  bgt $t7,$zero,DIGROWTR # if row element == digit, then true
  li $s3,0 # Set boolean (digit found in row element) to false
  addiu	$t0,$t0,2	# Get next element in row
  addiu	$t3,$t3,-1	# Subtract from counter
  b	ROWLP
DIGROWTR:
  li $s3,1 # Set boolean (digit found in row element) to true
ROWDN:
  and $s4,$s4,$s3 # Set boolean to true if all digits found in one row
  addi $t1,$t1,1 # Get next element in digits[i++]
  lb $s2,($t1) # Load next byte in digits[i++]
  mul $t5,$t4,18 # Go back to beginning of row: row offset = row# * 9
  move $t0,$s0 # Move back to sudoku initial address
  add $t0,$t0,$t5 # Add offset to address to get to next row
  b SRCHROWLP
SRCHROWDN:
  and $s5,$s5,$s4 # Set boolean to true if all digits found in all rows
  move $t1,$s1 # Move back to digits initial address
  lb $s2,($t1) # get digits[0]
  addiu	$t4,$t4,1	# Add to counter
  mul $t5,$t4,18 # Go to beginning of new row: row offset = row# * 18
  move $t0,$s0 # Move back to sudoku initial address
  add $t0,$t0,$t5 # Add offset to address to get to next row
  b NEXTROWLP
NEXTROWDN:
  move $v0,$s5 # Return boolean
	jr	$ra			# Return to calling routing

GETCOL:
  move $s0,$a0 # Preserve sudoku
  move $t0,$s0 # Move sudoku to temporary
  move $s1,$a1 # Preserve digits
  move $t1,$s1 # Move digits to temporary
  lb $s2,($t1) # Get digits[0]
  li $s4,1 # Set boolean (digit found in one col) to true
  li $s5,1 # Set boolean (digit found in all cols) to true
  li $t4,0 # Counter for total number of cols
NEXTCOLLP: # Loops through each col in puzzle
  beq $t4,9,NEXTCOLDN # Branch to NEXTCOLDN if counter is 9
SRCHCOLLP: # Loops digits to pick one digit
  beq $s2,$zero,SRCHCOLDN # Branch if string terminates
  li $t3,9 # Counter for number of elements in row (e.g. columns)
COLLP: # Loops one col to search for digit
  beq	$t3,$zero,COLDN	# Branch to COLDN if counter is 0
  lb	$a0,0($t0)	# load character to look for in row
  seq $t7,$a0,$s2 # compare col element and digit
  bgt $t7,$zero,DIGCOLTR # if col element == digit, then true
  li $s3,0 # Set boolean (digit found in row element) to false
  addiu	$t0,$t0,18	# Get next element in col
  addiu	$t3,$t3,-1	# Subtract from counter
  b	COLLP
DIGCOLTR:
  li $s3,1 # Set boolean (digit found in col element) to true
COLDN:
  and $s4,$s4,$s3 # Set boolean to true if all digits found in one col
  addi $t1,$t1,1 # Get next element in digits[i++]
  lb $s2,($t1) # Load next byte in digits[i++]
  mul $t5,$t4,2 # Go back to beginning: col offset
  move $t0,$s0 # Move back to sudoku initial address
  add $t0,$t0,$t5 # Add offset to address to get to next col
  b SRCHCOLLP
SRCHCOLDN:
  and $s5,$s5,$s4 # Set boolean to true if all digits found in all cols
  move $t1,$s1 # Move back to digits initial address
  lb $s2,($t1) # get digits[0]
  addiu	$t4,$t4,1	# Add to counter
  mul $t5,$t4,2 # Go to beginning of new col: col offset
  move $t0,$s0 # Move back to sudoku initial address
  add $t0,$t0,$t5 # Add offset to address to get to next col
  b NEXTCOLLP
NEXTCOLDN:
  move $v0,$s5 # Return boolean
	jr	$ra			# Return to calling routing

GETBOX:
  move $s0,$a0 # Preserve parameter
  move $t0,$s0 # Move parameter
  move $s1,$a1 # Preserve digits
  move $t1,$s1 # Move digits to temporary
  lb $s2,($t1) # Get digits[0]
  li $t4,0 # Set up counter for 3 boxes in 3 columns
BOXCOLLP: # Loop through every column of boxes
  beq	$t4,3,BOXCOLDN	# Branch to BOXCOLDN if counter is 3
  li $t3,0 # Set up counter for 3 boxes in 3 rows
BOXROWLP: # Loop through every row of boxes
  beq	$t3,3,BOXROWDN	# Branch to BOXROWDN if counter is 3
  li $s3,1 # Boolean for digit in 3x3 box
SRCHBOXLP:
  beq $s2,$zero,SRCHBOXDN
  li $t6,0 # Temporary boolean to find digit in element
  lb	$a0,0($t0)	# Get first number in 3x3 box
  seq $t7,$a0,$s2 # Compare element and digit
  xor $t6,$t6,$t7 # If element == digit, then true
  lb	$a0,2($t0)	# Get second number in 3x3
  seq $t7,$a0,$s2 # Compare element and digit
  xor $t6,$t6,$t7#  If element == digit, then true
  lb	$a0,4($t0)	# Get third number in 3x3
  seq $t7,$a0,$s2 # Compare element and digit
  xor $t6,$t6,$t7 # iIf element == digit, then true
  lb	$a0,18($t0)	# Get fourth number in 3x3
  seq $t7,$a0,$s2 # Compare element and digit
  xor $t6,$t6,$t7 # If element == digit, then true
  lb	$a0,20($t0)	# Get fifth number in 3x3
  seq $t7,$a0,$s2 # Compare element and digit
  xor $t6,$t6,$t7 # If element == digit, then true
  lb	$a0,22($t0)	# Get sixth number in 3x3
  seq $t7,$a0,$s2 # Compare element and digit
  xor $t6,$t6,$t7 # If element == digit, then true
  lb	$a0,36($t0)	# Get seventh number in 3x3
  seq $t7,$a0,$s2 # Compare element and digit
  xor $t6,$t6,$t7 # If element == digit, then true
  lb	$a0,38($t0)	# Get eighth number in 3x3
  seq $t7,$a0,$s2 # Compare element and digit
  xor $t6,$t6,$t7 # If element == digit, then true
  lb	$a0,40($t0)	# Get nineth number in 3x3
  seq $t7,$a0,$s2 # Compare element and digit
  xor $t6,$t6,$t7 # If element == digit, then true
  and $s3,$s3,$t6 # if element != digit, then false
  addi $t1,$t1,1 # Get next element in digits[i++]
  lb $s2,($t1) # Load next byte in digits[i++]
  b SRCHBOXLP
SRCHBOXDN:
  and $s4,$s4,$s3 # If all elements == a digit 1-9, then true
  move $t1,$s1 # Move back to digits initial address
  lb $s2,($t1) # Get digits[0]
  addiu	$t3,$t3,1	# Add to counter
  add $t0,$t0,54 # Skip over to next row of boxes (18 bytes * 3 rows)
  b	BOXROWLP
BOXROWDN:
  addiu	$t4,$t4,1	# Add to counter
  move $t0,$s0 # Start back at initial address
  mul $t5,$t4,6 # Skip over to next column of boxes (2 bytes * 3 numbers)
  add $t0,$t0,$t5 # Increment array address
  b BOXCOLLP
BOXCOLDN:
  move $v0,$s4 # Return boolean
	jr	$ra			# Return to calling routing
