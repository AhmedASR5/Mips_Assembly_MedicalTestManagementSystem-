.data

filename: .asciiz "testResults.txt"

openFlags: .word 0x0001       # Flag for write and create
mode: .word 0x01B6            # Mode for file permissions (0644)


promptID: .asciiz "Enter Patient ID (7 digits): "
idBuffer: .space 11 # Buffer for ID, assuming max 10 chars + null terminator

promptTestName: .asciiz "\nEnter Test Name: "
testName: .space 7 # Space for the name

promptTestDate: .asciiz "\nEnter Test Date (YYYY-MM): "
testDate: .space 9  # Space for "YYYY-MM" + null terminator

promptTestResult: .asciiz "\nEnter Test Result (as a floating-point number): "
.align 3  # Align the next data declaration on a doubleword boundary
floatBuffer: .space 8  # Reserve 8 bytes for storing a double-precision float


msgValid: .asciiz "\nValid ID.\n"
msgInvalid: .asciiz "\nInvalid ID. Must be exactly 7 digits.\n"


menu: .asciiz "\n--- Medical Test System Menu ---\n1. Add a new medical test\n2. Retrieve all patient tests by patient ID\n3. Retrieve all up normal patient tests\n4. Retrieve all patient tests in a given specific period\n5. Search for unnormal tests\n6. Average test value\n7. Update an existing test result\n8. Delete a test\n9. Exit\nSelect an option: "
invalidOption: .asciiz "Invalid option. Please try again.\n"
prompt: .asciiz "Your choice: "


menuTestNames: .asciiz "\n Select a Medical Test by entering the corresponding number:\n 1. Hemoglobin (Hgb)\n 2. Blood Glucose Test (BGT)\n 3. LDL Cholesterol (LDL)\n 4. Blood Pressure Test (BPT)\n Enter your choice: "

promptInvalid: .asciiz "Invalid choice. Please try again.\n"

hemoglobin: .asciiz "Hgb"
blood_glucose_test: .asciiz "BGT"
ldl_cholesterol: .asciiz "LDL"
blood_pressure_test: .asciiz "BPT"



completeRecord: .space 100  # Adjust based on your needs
delimiter: .asciiz ", "
newline: .asciiz "\n"


# for search test by ID ---------------------

buffer: .space 1024    # Increase buffer size if needed, but ensure it matches the read size below.
readSize: .word 2024    # Number of bytes to read at a time; adjust as per buffer size.

inputPrompt: .asciiz "\nEnter the Patient ID'): "
inputBuffer_ID: .space 11  # Buffer for search id 
error_msg: .asciiz "Failed to open the file.\n"

#end of search test by ID ---------------------


# for average test value ---------------------

outputString: .space 50  # Allocate space for the output string
semicolonCount: .word 0  # Counter for the number of semicolons

integerPart: .word 0       # Space for the integer part
fractionalPart: .word 0    # Space for the fractional part as an integer
scale: .word 1             # Scale

messageHgb: .asciiz "Average Hgb: "
messageBGT: .asciiz "Average BGT: "
messageLDL: .asciiz "Average LDL: "
messageBPT: .asciiz "Average BPT: "

zero_float: .float 0.0   # Define a floating point zero constant in data segment


#end of average test value ---------------------

.text
.globl main

main:

#----------------------------------------Menu--------------------------------     

menu_loop:

    # Display menu
    li $v0, 4
    la $a0, menu
    syscall

    # Read user's choice
    li $v0, 5
    syscall
    move $t0, $v0  # Move user's choice into $t0

    # Compare user's choice and jump to the corresponding procedure
    li $t1, 1
    beq $t0, $t1, add_test
    
    li $t1, 2
    beq $t0, $t1, search_test

    li $t1, 3
    beq $t0, $t1, retrieve_all_up_normal_tests
    
    li $t1, 4
    beq $t0, $t1, retrieve_all_tests_in_period

    li $t1, 5
    beq $t0, $t1, search_unnormal_tests

    li $t1, 6
    beq $t0, $t1, average_test_value

    li $t1, 7
    beq $t0, $t1, update_existing_test_result

    li $t1, 8
    beq $t0, $t1, delete_test

   # Process user's choice
    li $t1, 9  # Exit option number
    beq $t0, $t1, exit_program  # If user chooses to exit

    # If invalid option, show error and go back to menu
    li $v0, 4
    la $a0, invalidOption
    syscall
    j menu_loop


exit_program:
    # Exit the program
    li $v0, 10
    syscall

#----------------------------------------Getting information from the user (Add test) --------------------------------

add_test:



#----------------------------------------Opening the file for writing----------------------------------------

# Open the file for writing

    # Open the file for writing
    li $v0, 13                 # Syscall: open file
    la $a0, filename           # Filename: pointer to "testResults.txt"
    lw $a1, openFlags          # Flags: write only
    syscall
    move $s7, $v0              # Save the file descriptor to $s7
    
    # Check if file opened successfully
    bltz $s7, open_failed  

#---------------------------------------- End of Opening the file for writing--------------------------------

    # Prompt for Patient ID
    li $v0, 4
    la $a0, promptID
    syscall

    # Read Patient ID as a string
    li $v0, 8
    la $a0, idBuffer
    li $a1, 11 # Max length to read
    syscall
    
    
      # Validate Patient ID
    la $a0, idBuffer # Load address of the ID buffer
    jal validatePatientID # Jump to the validation function

    # Check if ID is valid (result returned in $v0, 1 = valid, 0 = invalid)
    li $t1, 1
    beq $v0, $t1, validID
    j invalidID
    
    finish_check: 
    
    
    #Read test name 

#-----------------------------------Selecting the test name--------------------------------    

test_name:

    #promt
    li $v0, 4
    la $a0, menuTestNames
    syscall

    # Read user's choice
    li $v0, 5
    syscall
    move $t0, $v0  # Move user's choice into $t0

    # Compare user's choice and jump to the corresponding procedure

    li $t1, 1
    beq $t0, $t1, hemoglobin_label

    li $t1, 2
    beq $t0, $t1, blood_glucose_test_label

    li $t1, 3
    beq $t0, $t1, ldl_cholesterol_label

    li $t1, 4
    beq $t0, $t1, blood_pressure_test_label

    # If invalid option, show error and go back to menu
    li $v0, 4
    la $a0, promptInvalid
    syscall
    j test_name

    # now save the test choises in in testName buffer



    hemoglobin_label:
                la $a0, testName     # Load the address of testName buffer
                la $a1, hemoglobin    # Load the address of "Hgb" string
                jal copy_loop        # Copy the "Hgb" string to the testName buffer
                j test_date          # Jump to the next step

    
    blood_glucose_test_label:
                la $a0, testName     # Load the address of testName buffer
                la $a1, blood_glucose_test    # Load the address of "BGT" string
                jal copy_loop        # Copy the "BGT" string to the testName buffer
                j test_date          # Jump to the next step


    ldl_cholesterol_label: 
                la $a0, testName     # Load the address of testName buffer
                la $a1, ldl_cholesterol    # Load the address of "LDL" string
                jal copy_loop        # Copy the "LDL" string to the testName buffer
                j test_date          # Jump to the next step

    blood_pressure_test_label:
                la $a0, testName     # Load the address of testName buffer
                la $a1, blood_pressure_test    # Load the address of "BPT" string
                jal copy_loop        # Copy the "BPT" string to the testName buffer
                j test_date          # Jump to the next step


                     


#-----------------------------------End of Selecting the test name--------------------------------


test_date:
    
    # Prompt and Read Test Date
    li $v0, 4
    la $a0, promptTestDate
    syscall

    li $v0, 8
    la $a0, testDate
    li $a1, 9
    syscall


    # Prompt the user for input
    li $v0, 4                  # Syscall for print string
    la $a0, promptTestResult             # Address of prompt string
    syscall


    li $v0, 8                  # Syscall code for reading a string
    la $a0, floatBuffer       # Address of buffer to store the string
    li $a1, 8                 # The maximum number of characters to read
    syscall

#----------------------------------- writing the information to the file--------------------------------


 # Replace newline with colon in testDate if present
    la $a0, idBuffer
    jal replace_newline_with_colon

    # Write Patient ID to the file
    li $v0, 15
    move $a0, $s7
    la $a1, idBuffer
    li $a2, 11                 # Example length, adjust based on actual content length
    syscall


    # Replace newline with comma in testName if present
    la $a0, testName
    jal replace_newline_with_comma

    # Write Test Name
    li $v0, 15
    move $a0, $s7
    la $a1, testName
    li $a2, 7             # Example length, adjust as needed
    syscall

    # Replace newline with comma in testDate if present
    la $a0, testDate
    jal replace_newline_with_comma

    # Write Test Date
    li $v0, 15
    move $a0, $s7
    la $a1, testDate
    li $a2, 9                  # Example length, adjust as needed
    syscall

    # Replace newline with space in floatBuffer if present

    la $a0, floatBuffer
    jal replace_newline_with_space

    # Write Test Result to the file
    li $v0, 15                 # Syscall for write to file
    move $a0, $s7             
    la $a1, floatBuffer      
    li $a2, 8 
    syscall


    # Write newline to the file
    li $v0, 15
    move $a0, $s7
    la $a1, newline
    li $a2, 1
    syscall


 # Close the file
    li $v0, 16                 # Syscall: close file
    move $a0, $s7              # File descriptor
    syscall
    
#-----------------------------------End of writing the information to the file--------------------------------


    # Return to the menu
    j menu_loop
    
    
  open_failed:
    # Handle file open failure
    li $v0, 10                 # Exit if failed to open
    syscall



#------------------------------------Getting information from the user----------------------------  

search_test: 

   # Close the file if the search opend at first by user
    li $v0, 16                 # Syscall: close file
    move $a0, $s7              # File descriptor
    syscall
    
   # Open the file for reading
    li $v0, 13               # sys_open
    la $a0, filename         # Pointer to the filename
    li $a1, 0                # Flag for reading
    syscall
    move $s6, $v0            # Save the file descriptor

    # Check for successful file opening
    bltz $s6, error_open


    li $v0, 14               # sys_read
    move $a0, $s6            # File descriptor
    la $a1, buffer           # Pointer to the buffer
    lw $a2, readSize         # Number of bytes to read
    syscall

    move $t1, $v0            # Store the number of bytes read in $t1
    beqz $v0, close_file     # If no bytes were read, end of file has been reached


  # Prompt user for the test ID
    li $v0, 4
    la $a0, inputPrompt
    syscall

    # Read the test ID as a string
    li $v0, 8
    la $a0, inputBuffer_ID
    li $a1, 20
    syscall

    # Search for the test ID in the buffer

    
 # Initialize $t3 with 0 for summing ASCII values of inputBuffer_ID
    li $t3, 0
    la $a0, inputBuffer_ID
    jal calculateSum       # Calculate sum of ASCII values in inputBuffer_ID
    move $t5, $v0          # Move result to $t5

    # Reset $t3 to 0 for use in comparing with each ID in buffer
    li $t3, 0
    la $a0, buffer         # Load address of the start of the buffer into $a0
    la $t7, buffer         # Initialize $t7 with the start of the buffer

loopPrintChar:

    lb $a1, 0($a0)         # Load the byte at the current buffer position into $a1
    beq $a1, ':', checkID              # If colon, check if ID matches

    addu $t3, $t3, $a1     # Add the ASCII value to the sum for ID comparison
    addiu $a0, $a0, 1      # Move to the next character in buffer
    j loopPrintChar

checkID:
    
    beq $t5, $t3, values_equal # Compare sum of ASCII values
    # If not equal, find the start of the next line
    jal findNextLine
    j loopPrintChar

values_equal:
    # Logic for printing the data after ID match

    move $a0, $t7          # Load the address of the start of the line into $a0
    j printData

findNextLine:

    # Find the start of the next line
    lb $a1, 0($a0)
    beq $a1, '\n', end_findNextLine    # New line found, prepare to process next ID
    addiu $a0, $a0, 1      # Move to the next character in buffer
    
    lb $a1, 0($a0)
    beq $a1, '\0', Done_file_reading  # Check for end of buffer
    
    j findNextLine
    
end_findNextLine:
    addiu $a0, $a0, 1      # Skip the newline character
    li $t3, 0              # Reset the sum for next ID
    move $t7, $a0          # Update the start of the next line
    j loopPrintChar        # Continue with next ID

printData:
    lb $a1, 0($a0)
    beq $a1, '\n', GoNextLine  # End of data for this ID
    move $a0, $a1
    li $v0, 11             # syscall for printing character
    syscall
    
    addiu $t7, $t7, 1      # Move to the next character in buffer
    move $a0, $t7          # Load the address of the start of the line into $a0
   
    j printData            # Continue printing data
    
GoNextLine:
    move $a0, $a1
    li $v0, 11             # syscall for printing character
    syscall
    addiu $t7, $t7, 1
    move $a0, $t7 
    li $t3, 0              # Reset the sum for next ID
    lb $a1, 0($a0)
    beq $a1, '\0', Done_file_reading  # Check for end of buffer
     
 j loopPrintChar


Done_file_reading:
     j menu_loop
     
     
calculateSum:
    # Input: $a0 (address of the string)
    # Output: $v0 (sum of ASCII values)
    li $v0, 0              # Initialize sum to 0
sum_loop:
    lb $t1, 0($a0)         # Load the next character
    beq $t1, '\0', end_sum # Check for end of string
    beq $t1, '\n', end_sum # Check for end of string
    addu $v0, $v0, $t1     # Add character's ASCII value to sum
    addiu $a0, $a0, 1      # Move to the next character
    j sum_loop
end_sum:
    jr $ra                 # Return with sum in $v0


error_open:
    li $v0, 4                # sys_write (print_string)
    la $a0, error_msg        # Pointer to the error message
    syscall

    li $v0, 10               # sys_exit
    syscall


close_file:
             
    # Close the file
    li $v0, 16               # sys_close
    move $a0, $s6            # File descriptor
    syscall

j menu_loop



retrieve_all_up_normal_tests:
    j menu_loop


retrieve_all_tests_in_period:
    j  menu_loop


search_unnormal_tests:
    j menu_loop


average_test_value:

   # choosing the reg s0 to s3 to save the count of each test result
    li $s1, 0 # for count of Hgb
    li $s2, 0 # for count of BGT
    li $s3, 0 # for count of LDL
    li $s4, 0 # for count of BPT

    # Initialize floating-point registers with zero
    la $a0, zero_float     # Load the address of the zero_float constant
    lwc1 $f20, 0($a0)      # Load the floating-point zero into $f20
    lwc1 $f21, 0($a0)      # Load the floating-point zero into $f21
    lwc1 $f22, 0($a0)      # Load the floating-point zero into $f22
    lwc1 $f23, 0($a0)      # Load the floating-point zero into $f23


   # Close the file if the search opend at first by user
    li $v0, 16                 # Syscall: close file
    move $a0, $s7              # File descriptor
    syscall
    
   # Open the file for reading
    li $v0, 13               # sys_open
    la $a0, filename         # Pointer to the filename
    li $a1, 0                # Flag for reading
    syscall
    move $s6, $v0            # Save the file descriptor

    # Check for successful file opening
    bltz $s6, error_open


    li $v0, 14               # sys_read
    move $a0, $s6            # File descriptor
    la $a1, buffer           # Pointer to the buffer
    lw $a2, readSize         # Number of bytes to read
    syscall

    move $t1, $v0            # Store the number of bytes read in $t1
    beqz $v0, close_file     # If no bytes were read, end of file has been reached



#-----------------------------------Getting the floating-point values from the file--------------------------------

    la $a0, buffer         # Load address of the start of the buffer into $a0
    la $t7, buffer         # Initialize $t7 with the start of the buffer
    la $a1, outputString   # Load address of the output string into $a1
    lw $t2, semicolonCount # Load the initial value of the semicolon counter into $t2

find_semicolon:

    lb $t0, 0($a0)        # Load the next character from the input string into $t0
    beq $t0, ':', determine_test_name # If colon, check if ID matches
    li $t1, ','           # Load the ASCII value of semicolon into $t1
    beq $t0, $t1, increment_counter # If the current character is a semicolon, increment the counter
    addiu $a0, $a0, 1     # Move to the next character in the input string
    j find_semicolon      # Jump back to the start of the loop

increment_counter:
    addiu $t2, $t2, 1     # Increment the semicolon counter
    sw $t2, semicolonCount # Store the updated counter
    addiu $a0, $a0, 1     # Move past the semicolon
    li $t3, 2             # We're looking for the second semicolon
    beq $t2, $t3, start_copying # If we've found two semicolons, start copying
    j find_semicolon      # Otherwise, keep looking for semicolons

start_copying:

    lb $t0, 0($a0)        # Load the next character from the input string into $t0
    beq $t0, ' ', skipSpace # Check for the space character
    beq $t0, '\n', continueToSecondLine # Check for the end of the line

    sb $t0, 0($a1)        # Store the character in the output string
    addiu $a0, $a0, 1     # Move to the next character in the input string
    addiu $a1, $a1, 1     # Move to the next position in the output string
    j start_copying       # Jump back to the start of the copy loop

skipSpace:
    addiu $a0, $a0, 1     # Move to the next character in the input string
   j start_copying

continueToSecondLine:

            move $t7, $a0          # save the start of the next line
            sb $t0, 0($a1)        # Store \n in the output string for use it for termination


            #before going to the next line, we need to sum the values of the test result to calculate the average

            #-----------------------------------sum the values of the test result to calculate the average--------------------------------

            beq $t4, 1, Hgb_test_sum
            beq $t4, 2, BGT_test_sum
            beq $t4, 3, LDL_test_sum
            beq $t4, 4, BPT_test_sum

            Hgb_test_sum:
                        la $a0, outputString   # Load address of the output string into $a0
                        jal parseString        # Jump to the string parsing function
                        jal convertPartsToFloatAndPrint
                        add.s $f20, $f20, $f1 
                        j doneSum


            BGT_test_sum:
                        la $a0, outputString   # Load address of the output string into $a0
                        jal parseString        # Jump to the string parsing function
                        jal convertPartsToFloatAndPrint
                        add.s $f21, $f21, $f1
			 j doneSum            


            LDL_test_sum:
                        la $a0, outputString   # Load address of the output string into $a0
                        jal parseString        # Jump to the string parsing function
                        jal convertPartsToFloatAndPrint
                        add.s $f22, $f22, $f1
                        j doneSum	
                        		
            BPT_test_sum: 
                        la $a0, outputString   # Load address of the output string into $a0
                        jal parseString        # Jump to the string parsing function
                        jal convertPartsToFloatAndPrint
                        add.s $f23, $f23, $f1


#-----------------------------------End of sum the values of the test result to calculate the average--------------------------

doneSum:

                addiu $t7, $t7, 1
                move $a0, $t7 
                li $t2, 0              # Reset the sum for next ID
                lb $a1, 0($a0)
                beq $a1, '\0', find_the_avg  # Check for end of buffer
                la $a1, outputString   # rest address of the output string into $a1
                
            j find_semicolon


find_the_avg:
            # Convert count from integer to floating-point
            mtc1 $s1, $f12  # Convert Hgb count to floating-point
            cvt.s.w $f12, $f12
            mtc1 $s2, $f13  # Convert BGT count to floating-point
            cvt.s.w $f13, $f13
            mtc1 $s3, $f14  # Convert LDL count to floating-point
            cvt.s.w $f14, $f14
            mtc1 $s4, $f15  # Convert BPT count to floating-point
            cvt.s.w $f15, $f15

            # Divide sum by count to find the average
            div.s $f12, $f20, $f12  # Average for Hgb
            div.s $f13, $f21, $f13  # Average for BGT
            div.s $f14, $f22, $f14  # Average for LDL
            div.s $f15, $f23, $f15  # Average for BPT
            
            
                   # Print newline character
   	     li $v0, 11          # System call for printing a character
             li $a0, 10          # Load ASCII value of newline ('\n') into $a0
             syscall 


            # Print each average
            li $v0, 4
            la $a0, messageHgb
            syscall
            
            
            li $v0, 2         # Print float
            mov.s $f12, $f12  # Load average Hgb for printing
            syscall
            
                # Print newline character
   	     li $v0, 11          # System call for printing a character
             li $a0, 10          # Load ASCII value of newline ('\n') into $a0
             syscall 

            li $v0, 4
            la $a0, messageBGT
            syscall
            
            
            li $v0, 2         # Print float
            mov.s $f12, $f13  # Load average BGT for printing
            syscall
            
                  # Print newline character
   	     li $v0, 11          # System call for printing a character
             li $a0, 10          # Load ASCII value of newline ('\n') into $a0
             syscall 


            li $v0, 4
            la $a0, messageLDL
            syscall
            
            
            li $v0, 2         # Print float
            mov.s $f12, $f14  # Load average LDL for printin
            syscall
            
                  # Print newline character
   	     li $v0, 11          # System call for printing a character
             li $a0, 10          # Load ASCII value of newline ('\n') into $a0
             syscall 


            li $v0, 4
            la $a0, messageBPT
            syscall
            
            mov.s $f12, $f15  # Load average BPT for printing
            li $v0, 2         # Print float
            syscall
            
                  # Print newline character
   	     li $v0, 11          # System call for printing a character
             li $a0, 10          # Load ASCII value of newline ('\n') into $a0
             syscall 


            j menu_loop
               

# -----------------------------------Get return uniqe value in t4 according to the test name-------------------------------- 

 
 determine_test_name: 
  li $t3, 0 # rest the value of asscii sum. 

 GetUniqeValueOfTestName:

  addiu $a0, $a0, 1      # Skip the : character
  move $t7, $a0          # Update the start of the next line 
   
  lb $t0, 0($a0)        # Load the next character from the input string into $t0
  beq $t0, ' ', GetUniqeValueOfTestName # Check for the end of the string
  
  # sum the ascii values of the test name to choose the test value to calculate the average
    beq $t0, ',', get_type_of_test # If colon, have unique value for each test name 
    addu $t3, $t3, $t0     # Add the ASCII value to the sum for test name comparison
    
    jal GetUniqeValueOfTestName


get_type_of_test:

    addiu $t2, $t2, 1     # Increment the semicolon counter
    sw $t2, semicolonCount # Store the updated counter

     # Check the sum of the ASCII values to determine the test name

    li $t1, 0x111        # ASCII sum for "Hgb"
    beq $t3, $t1, Hgb_test # If the sum matches "Hgb", jump to Hgb_test

    li $t1, 0xDD         #  ASCII sum for "BGT"
    beq $t3, $t1, BGT_test # If the sum matches "BGT", jump to BGT_test

    li $t1, 0xDC        #  ASCII sum for "LDL"
    beq $t3, $t1, LDL_test # If the sum matches "LDL", jump to LDL_test

    li $t1, 0xE6         #  ASCII sum for "BPT"
    beq $t3, $t1, BPT_test # If the sum matches "BPT", jump to BPT_test

#return unique value for each test name

    Hgb_test:
        li $t4, 1
        addiu $s1, $s1, 1
        addiu $a0, $a0, 1 # skip comma 
        j find_semicolon

    BGT_test:
        li $t4, 2
        addiu $s2, $s2, 1
        addiu $a0, $a0, 1 
        j find_semicolon

    LDL_test:
        li $t4, 3
        addiu $s3, $s3, 1
        addiu $a0, $a0, 1
        j find_semicolon

    BPT_test:
        li $t4, 4
        addiu $s4, $s4, 1
        addiu $a0, $a0, 1
        j find_semicolon    


#-----------------------------------end of Get return uniqe value in t4 according to the test name------------------------



#----------------------------------------------end of get average test value-----------------------------------------------


update_existing_test_result:
    j menu_loop


delete_test:
    j menu_loop

 
#---------------------------------------Functions area--------------------------------------------
validID:
    li $v0, 4
    la $a0, msgValid
    syscall
    j finish_check

invalidID:
    li $v0, 4
    la $a0, msgInvalid
    syscall
    j finish_check

validatePatientID:
    li $t0, 0 # Counter for digits
    loop:
        lb $t1, 0($a0) # Load byte (character) from buffer
        
	beq $t1, 10, checkLength # If end of string (\n), go to checkLength
        # Check if the character is a digit
        li $t2, 48 # ASCII '0'
        li $t3, 57 # ASCII '9'
        
        blt $t1, $t2, invalid # Less than '0'
        bgt $t1, $t3, invalid # Greater than '9'
        
        addi $t0, $t0, 1 # Increment counter
        addi $a0, $a0, 1 # Move to the next character
        j loop
    
    checkLength:
        li $t1, 7
        bne $t0, $t1, invalid # If counter != 7, invalid
        li $v0, 1 # Set return value to valid
        jr $ra

    invalid:
        li $v0, 0 # Set return value to invalid
        jr $ra

replace_newline_with_comma:
    lb $t0, 0($a0)                # Load the current byte from the buffer into $t0
    beq $t0, $zero, end_replacement  # If we've hit the null terminator, exit the loop
    
    li $t1, 0x0A                  # ASCII value of '\n'
    li $t3, 0x20                  # ASCII value of space ' '
    bne $t0, $t1, check_space     # If the current byte is not '\n', check for space

    # If we've found a newline character, replace it with a comma
    li $t2, 0x2C                  # ASCII value of ','
    sb $t2, 0($a0)                # Store the comma in place of the newline character
    j next_char                   # Proceed to the next character

check_space:
    bne $t0, $t3, next_char       # If the current byte is not space, go to the next character
    
    # Here, we found a space and want to "remove" it by shifting subsequent characters left.
    # This loop will start from the current space character's position.
shift_loop:
    lb $t4, 1($a0)                # Load the next byte into $t4
    sb $t4, 0($a0)                # Overwrite the current byte with the next byte
    beqz $t4, end_replacement     # If we've hit a null terminator during shifting, we're done
    addiu $a0, $a0, 1             # Move to the next character in the buffer
    j shift_loop                  # Continue shifting until we hit a null terminator

next_char:
    addiu $a0, $a0, 1             # Move to the next character in the buffer
    j replace_newline_with_comma  # Repeat the loop

end_replacement:
    jr $ra                        # Return from the function




replace_newline_with_space:
    lb $t0, 0($a0)            # Load the current byte from the buffer into $t0

loop2:
    beq $t0, $zero, end2       # If we've hit the null terminator, exit the loop
    li $t1, 0x0A              # ASCII value of '\n'
    bne $t0, $t1, check_next2  # If the current byte is not '\n', go to the next character
    
    # If we've found a newline character, replace it with a space
    li $t2, 0x20              # ASCII value of space ' '
    sb $t2, 0($a0)            # Store the space in place of the newline character

check_next2:
    addiu $a0, $a0, 1         # Move to the next character in the buffer
    lb $t0, 0($a0)            # Load the next byte from the buffer into $t0
    j loop2                    # Repeat the loop

end2:
    jr $ra                    # Return from the function


replace_newline_with_colon:
    lb $t0, 0($a0)            # Load the current byte from the buffer into $t0

loop3:
    beq $t0, $zero, end3       # If we've hit the null terminator, exit the loop
    li $t1, 0x0A              # ASCII value of '\n'
    bne $t0, $t1, check_next3  # If the current byte is not '\n', go to the next character
    
    # If we've found a newline character, replace it with a colon
    li $t2, 0x3A              # ASCII value of ':'
    sb $t2, 0($a0)            # Store the colon in place of the newline character

check_next3:
    addiu $a0, $a0, 1         # Move to the next character in the buffer
    lb $t0, 0($a0)            # Load the next byte from the buffer into $t0
    j loop3                    # Repeat the loop

end3:
    jr $ra                    # Return from the function


copy_loop:
    lb $t0, 0($a1)       # Load byte from source string
    sb $t0, 0($a0)       # Store byte in destination buffer
    beqz $t0, add_newline # If null terminator, prepare to add newline
    addiu $a0, $a0, 1    # Increment destination address
    addiu $a1, $a1, 1    # Increment source address
    j copy_loop          # Jump back to start of loop

add_newline:
    li $t1, 0x0A        # Load ASCII value of '\n'
    sb $t1, 0($a0)      # Store newline character at the end
    addiu $a0, $a0, 1   # Increment destination address
    sb $zero, 0($a0)    # Add null terminator after the newline

    jr $ra              # Return from function

invalidInput:
    li $v0, 4    # Print error message
    la $a0, error_msg
    syscall
    
    li $v0, 0    # Set return value to 0 to indicate an error
    jr $ra  # Return after handling invalid input



#-------------------------------------string to float conversion --------------------------------------------

parseString:
    # Initialize variables
    li $t1, 0              # Will hold the integer part
    li $t2, 0              # Will hold the fractional part
    li $t3, 1              # Will be used for the scale
    
    # Parse the integer part
parseInteger:
    lb $t0, 0($a0)         # Load the next byte (character) from the string
    beq $t0, '.', endInteger # Check for decimal point    
    sub $t0, $t0, '0'      # Convert from ASCII to integer
    mul $t1, $t1, 10       # Multiply current result by 10
    add $t1, $t1, $t0      # Add the new digit
    
    addiu $a0, $a0, 1      # Move to the next character
    j parseInteger         # Loop back

endInteger:
    sw $t1, integerPart    # Store the integer part
    addiu $a0, $a0, 1      # Move past the decimal point

    # Parse the fractional part
parseFractional:
    lb $t0, 0($a0)         # Load the next byte (character)
    beq $t0, '\n', endFractional # Check for null terminator
    
    sub $t0, $t0, '0'      # Convert from ASCII to integer
    mul $t2, $t2, 10       # Multiply current result by 10
    add $t2, $t2, $t0      # Add the new digit
    
    mul $t3, $t3, 10       # Increase scale
    addiu $a0, $a0, 1      # Move to the next character
    j parseFractional      # Loop back

endFractional:
    sw $t2, fractionalPart # Store the fractional part
    sw $t3, scale          # Store the scale
    jr $ra                 # Return

# Function to convert the parts to floating point and print
convertPartsToFloatAndPrint:
    # Load and convert integer part
    lw $s0, integerPart
    mtc1 $s0, $f1
    cvt.s.w $f1, $f1

    # Load and convert fractional part
    lw $s0, fractionalPart
    mtc1 $s0, $f2
    cvt.s.w $f2, $f2

    # Load and convert scale
    lw $s0, scale
    mtc1 $s0, $f3
    cvt.s.w $f3, $f3

    # Divide fractional part by scale
    div.s $f2, $f2, $f3

    # Combine integer and fractional parts
    add.s $f1, $f1, $f2
    
    jr $ra                 # Return
	
#---------------------------------------End of string to float conversion--------------------------------------------

#---------------------------------------Functions area--------------------------------------------        

end:
    # Exit program
    li $v0, 10
    syscall

