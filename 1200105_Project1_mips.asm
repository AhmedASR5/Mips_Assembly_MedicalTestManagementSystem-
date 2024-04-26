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
floatBuffer: .space 20  # Reserve 8 bytes for storing a double-precision float


msgValid: .asciiz "\nValid ID.\n"
msgInvalid: .asciiz "\nInvalid ID. Must be exactly 7 digits.\n"


menu: .asciiz "\n--- Medical Test System Menu ---\n1. Add a new medical test\n2. Retrieve all patient tests by patient ID\n3. Retrieve all normal patient tests by patient ID \n4.Retrieve all up normal patient tests \n5.Retrieve all patient tests in a given specific period\n6.Search for unnormal tests based on the input medical test\n7. Average test value\n8. Update an existing test result\n9. Delete a test\n10. Exit\nSelect an option: "
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
buffer_temp: .space 1024   # use it in udpate test result
readSize: .word 2024    # Number of bytes to read at a time; adjust as per buffer size.

inputPrompt: .asciiz "\nEnter the Patient ID'): "
inputBuffer_ID: .space 11  # Buffer for search id 
error_msg: .asciiz "Failed to open the file.\n"

test_result_found: .asciiz "The test result is found successfully.\n"


#end of search test by ID ---------------------


# for average test value ---------------------

outputString: .space 50  # Allocate space for the output string
outputString2: .space 50 
integerPart: .word 0       # Space for the integer part
fractionalPart: .word 0    # Space for the fractional part as an integer
scale: .word 1             # Scale

messageHgb: .asciiz "Average Hgb: "
messageBGT: .asciiz "Average BGT: "
messageLDL: .asciiz "Average LDL: "
messageBPT: .asciiz "Average BPT: "



zero_float: .float 0.0   # Define a floating point zero constant in data segment


#end of average test value ---------------------

#For normal and unnormal test ---------------------

    lowerBoundHgb: .float 13.8
    upperBoundHgb: .float 17.2
    lowerBoundBGT: .float 70.0
    upperBoundBGT: .float 99.0
    upperBoundLDL: .float 100.0
    upperBoundSystolicBPT: .float 120.0
    upperBoundDiastolicBPT: .float 80.0
    
    floatReturned: .asciiz "float returned is : "

#end of normal and unnormal test ---------------------

#for specific period ---------------------


patient_id_period:  .word 0
first_year:       .word 0
first_month:      .word 0
second_year:      .word 0
second_month:     .word 0
patient_id_prompt: .asciiz "Please enter patient ID: "

year_prompt: .asciiz "\nEnter year first (as 4 digits yyyy):"
month_prompt: .asciiz "\nEnter first month (as 2 digits mm): "
year_prompt2: .asciiz "\nEnter year second (as 4 digits yyyy):"
month_prompt2: .asciiz "\nEnter second month (as 2 digits mm): "

first_date_prompt: .asciiz "\nEnter the first date (YYYY-MM)"
second_date_prompt: .asciiz "\nEnter the second date (YYYY-MM)"


#end of specific period -------------------

#for unnormal test ---------------------

found_unnormal_test: .asciiz "The unnormal test is found successfully.\n"

#end of unnormal test -------------------


#for update and delete test result ---------------------

address_of_test_vlaue_to_change: .word 0
user_test_new_value: .word 0
not_found_recorde: .asciiz "The test recorde is not found in the file.\n Please try again.\n"
test_result_updated_promt: .asciiz "The test result is updated successfully.\n"
test_result_deleted_promt: .asciiz "The test result is deleted successfully.\n"
bool_found: .word 0 
end_target_line_address: .word 0


#end of update test result -------------------

.text
.globl main

main:

#----------------------------------------Menu--------------------------------     

menu_loop:


    jal openReadFile

    # Display menu
    li $v0, 4
    la $a0, menu
    syscall

    # Read user's choice
    li $v0, 5
    syscall
    move $t0, $v0  # Move user's choice into $t0

#menu: .asciiz "\n--- Medical Test System Menu ---\n1. Add a new medical test\n2. Retrieve all patient tests by patient ID\n3. Retrieve all normal patient tests by patient ID \n4.Retrieve all up normal patient tests \n5.Retrieve all patient tests in a given specific period\n6.Search for unnormal tests based on the input medical test\n7. Average test value\n8. Update an existing test result\n9. Delete a test\n10. Exit\nSelect an option: "

    # Compare user's choice and jump to the corresponding procedure
    li $t1, 1
    beq $t0, $t1, add_test
    
    li $t1, 2
    beq $t0, $t1, search_patient_tests_by_ID

    li $t1, 3
    beq $t0, $t1, retrieve_all_normal_tests_by_ID

    li $t1, 4
    beq $t0, $t1, retrieve_all_unnormal_tests_by_ID
    
    li $t1, 5
    beq $t0, $t1, retrieve_all_tests_in_period

    li $t1, 6
    beq $t0, $t1, search_unnormal_tests_by_input_test

    li $t1, 7
    beq $t0, $t1, average_test_value

    li $t1, 8
    li $s6, 0 # reset the flag to 0
    beq $t0, $t1, update_existing_test_result 

    li $t1, 9
    # this function use update function , 
    beq $t0, $t1, delete_test

   # Process user's choice
    li $t1, 10  # Exit option number
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
    li $a1, 20                 # The maximum number of characters to read
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
    li $a2, 20
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

search_patient_tests_by_ID: 

  
  # Prompt user for the test ID
    li $v0, 4
    la $a0, inputPrompt
    syscall

    # Read the test ID as a string
    li $v0, 8
    la $a0, inputBuffer_ID
    li $a1, 20
    syscall


li $s7, 0 # Initialize the flag to 0
la $a0, buffer # Load the address of the buffer into $a0


cheack_for_patient_ID_to_retrieve:

    move $t9, $a0 # Save the address of the start of the buffer in $t7

    jal BoolIDCheck # f(a0 , inputbuffer_ID) retrun 1 in t5 if the ID is equal to the inputBuffer_ID

    #if the t5 = 1 mean the ID is equal to the inputBuffer_ID
    #else the ID is not equal to the inputBuffer_ID

    beq $t5, 1, print_id_match
    jal get_next_line
    beq $s7, 1, check_founded_bool_retreive_all_tests
    j cheack_for_patient_ID_to_retrieve



  
print_id_match: 
          
            
                              #store in bool_found the value 1 to indicate that the test result is found
          li $t1, 1
          sw $t1, bool_found
          move $a0, $t9           # Load the address of the start of the line into $a0
          jal printLine             # Jump to printLine to print the data for this line                 
          beq $s7, 1, check_founded_bool_retreive_all_tests   # If the end of the file is reached, return to the menu
          j cheack_for_patient_ID_to_retrieve       # Continue to check file IDs


  check_founded_bool_retreive_all_tests:

            #if the bool_found = 1 mean the test result is found and updated
            #else the test result is not found and not updated

            lw $t1, bool_found
            beq $t1, 1, retrieved_all_tests_to_print

            #if the test result is not found

            #print new line character

            li $v0, 11          # System call for printing a character
            li $a0, 10          # Load ASCII value of newline ('\n') into $a0
            syscall


            li $v0, 4
            la $a0, not_found_recorde
            syscall

            li $v0, 11          # System call for printing a character
            li $a0, 10          # Load ASCII value of newline ('\n') into $a0
            syscall

            j menu_loop

            
      
        retrieved_all_tests_to_print:

                li $v0, 11          # System call for printing a character
                li $a0, 10          # Load ASCII value of newline ('\n') into $a0
                syscall        
                
                li $v0, 4
                la $a0, test_result_found
                syscall

                li $v0, 11          # System call for printing a character
                li $a0, 10          # Load ASCII value of newline ('\n') into $a0
                syscall

                #reset the bool_found to 0
                li $t1, 0
                sw $t1, bool_found

                j menu_loop							
                                                        
                                                                                           
                        
     j menu_loop
     
     

retrieve_all_normal_tests_by_ID:

  # Prompt user for the test ID
    li $v0, 4
    la $a0, inputPrompt
    syscall

    # Read the test ID as a string
    li $v0, 8
    la $a0, inputBuffer_ID
    li $a1, 20
    syscall


li $s7, 0 # Initialize the flag to 0
la $a0, buffer # Load the address of the buffer into $a0


cheack_file_IDs:

    move $t9, $a0 # Save the address of the start of the buffer in $t7

    jal BoolIDCheck # f(a0 , inputbuffer_ID) retrun 1 in t5 if the ID is equal to the inputBuffer_ID

    #if the t5 = 1 mean the ID is equal to the inputBuffer_ID
    #else the ID is not equal to the inputBuffer_ID

    beq $t5, 1, check_test_resultNormal
    jal get_next_line
    beq $s7, 1, menu_loop
    j cheack_file_IDs



  
    # Logic for printing the data after ID match

    #normal range for each test
    #1. Hemoglobin (Hgb): 13.8 to 17.2 grams per deciliter 
    #2. Blood Glucose Test (BGT): Normal Range Between 70 to 99 milligrams per deciliter (mg/dL) 
    #3. LDL Cholesterol Low-Density Lipoprotein (LDL): Normal Range Less than 100 mg/dL
    #4. Blood Pressure Test (BPT): Normal Range: Systolic Blood Pressure: Less than 120 millimeters of 
    #   mercury (mm Hg). Diastolic Blood Pressure: Less than 80 mm Hg 

check_test_resultNormal: 

            move $a0, $t9          # Load the address of the start of the line into $a0
            jal line_test_values # f(a0) retrun F1 = test result in floating point, t4 = type of test, a0 = start of the next line

            #-----------------------------------sum the values of the test result to calculate the average--------------------------------
            
            beq $t4, 1, Hgb_test_Normal
            beq $t4, 2, BGT_test_Normal
            beq $t4, 3, LDL_test_Normal
            beq $t4, 4, BPT_test_Normal


            Hgb_test_Normal:
                            lwc1 $f3, lowerBoundHgb # Load the lower bound value, which is 13.8
                            lwc1 $f4, upperBoundHgb # Load the upper bound value, which is 17.2

                            c.lt.s $f1, $f3         # Compare the test result in $f1 with the lower bound $f3
                            bc1t if_it_unnormal   # If the test result is less than the lower bound, branch to if_it_unnormal

                            c.le.s $f4, $f1         # Compare the test result in $f1 with the upper bound $f4
                            bc1t if_it_unnormal   # If the test result is greater than the upper bound, branch to if_it_unnormal

                            move $a0, $t9           # Load the address of the start of the line into $a0
                            jal printLine             # Jump to printLine to print the data for this line
                            
                            beq $s7, 1, menu_loop   # If the end of the file is reached, return to the menu
                            j cheack_file_IDs       # Continue to check file IDs							
                                                        
                                    
                    
            BGT_test_Normal:

                           lwc1 $f3, lowerBoundBGT # Load the lower bound value is 70.0
                           lwc1 $f4, upperBoundBGT # Load the upper bound value is 99.0

                           c.lt.s $f1, $f3         # Compare the test result in $f1 with the lower bound $f3
                           bc1t if_it_unnormal   # If the test result is less than the lower bound, branch to if_it_unnormal

                           c.le.s $f4, $f1         # Compare the test result in $f1 with the upper bound $f4
                           bc1t if_it_unnormal   # If the test result is greater than the upper bound, branch to if_it_unnormal
                           
                           move $a0, $t9          # Load the address of the start of the line into $a0
                           jal printLine          # f(a0) print the data for this line 

                           beq $s7, 1, menu_loop
                           j  cheack_file_IDs                                        

            LDL_test_Normal:

                            lwc1 $f4, upperBoundLDL  # Load the upper bound value of 100.0 into $f3
                            c.le.s $f4, $f1          # Compare the test result in $f1 with the upper bound in $f3
                            bc1t if_it_unnormal    # If $f1 is not less than or equal to $f3 (i.e., $f1 is greater than $f3), branch to end_findNextLine

                            move $a0, $t9          # Load the address of the start of the line into $a0
                            jal printLine          # f(a0) print the data for this line 

                            beq $s7, 1, menu_loop
                            j  cheack_file_IDs         
                        		
            BPT_test_Normal: 
                            lwc1 $f4, upperBoundSystolicBPT # Load the upper bound value is 120.0
                            lwc1 $f3, upperBoundDiastolicBPT # Load the upper bound value is 80.0

                            c.le.s $f3 , $f2             # Compare the test result in $f1 with the lower bound $f3
                            bc1t if_it_unnormal   # If the test result is less than the lower bound, branch to if_it_unnormal

                            c.le.s $f4, $f1         # Compare the test result in $f1 with the upper bound $f4
                            bc1t if_it_unnormal   # If the test result is greater than the upper bound, branch to if_it_unnormal

                            move $a0, $t9          # Load the address of the start of the line into $a0
                            jal printLine          # f(a0) print the data for this line 
                            
                            beq $s7, 1, menu_loop
                            j  cheack_file_IDs


    if_it_unnormal:
    
                  move $a0, $t9          # Load the address of the start of the line into $a0  
                  jal get_next_line
                  j cheack_file_IDs

                                                    
                            
                        
    j menu_loop



retrieve_all_unnormal_tests_by_ID:

  # Prompt user for the test ID
    li $v0, 4
    la $a0, inputPrompt
    syscall

    # Read the test ID as a string
    li $v0, 8
    la $a0, inputBuffer_ID
    li $a1, 20
    syscall


li $s7, 0 # Initialize the flag to 0
la $a0, buffer # Load the address of the buffer into $a0


cheack_file_IDs_unnormal:

    move $t9, $a0 # Save the address of the start of the buffer in $t7

    jal BoolIDCheck # f(a0 , inputbuffer_ID) retrun 1 in t5 if the ID is equal to the inputBuffer_ID

    #if the t5 = 1 mean the ID is equal to the inputBuffer_ID
    #else the ID is not equal to the inputBuffer_ID

    beq $t5, 1, check_test_resultUnnormal
    jal get_next_line
    beq $s7, 1, menu_loop
    j cheack_file_IDs_unnormal



  
    # Logic for printing the data after ID match

    #normal range for each test
    #1. Hemoglobin (Hgb): 13.8 to 17.2 grams per deciliter 
    #2. Blood Glucose Test (BGT): Normal Range Between 70 to 99 milligrams per deciliter (mg/dL) 
    #3. LDL Cholesterol Low-Density Lipoprotein (LDL): Normal Range Less than 100 mg/dL
    #4. Blood Pressure Test (BPT): Normal Range: Systolic Blood Pressure: Less than 120 millimeters of 
    #   mercury (mm Hg). Diastolic Blood Pressure: Less than 80 mm Hg 

check_test_resultUnnormal: 

            move $a0, $t9          # Load the address of the start of the line into $a0
            jal line_test_values # f(a0) retrun F1 = test result in floating point, t4 = type of test, a0 = start of the next line

            #-----------------------------------sum the values of the test result to calculate the average--------------------------------
            
            beq $t4, 1, Hgb_test_unnormal
            beq $t4, 2, BGT_test_unnormal
            beq $t4, 3, LDL_test_unnormal
            beq $t4, 4, BPT_test_unnormal


            Hgb_test_unnormal:

                            lwc1 $f3, lowerBoundHgb # Load the lower bound value, which is 13.8
                            lwc1 $f4, upperBoundHgb # Load the upper bound value, which is 17.2

                            c.lt.s $f1, $f3         # Compare the test result in $f1 with the lower bound $f3
                            bc1t printIfUnnormal   # If the test result is less than the lower bound, branch to if_it_unnormal

                            c.le.s $f4, $f1         # Compare the test result in $f1 with the upper bound $f4
                            bc1t printIfUnnormal   # If the test result is greater than the upper bound, branch to if_it_unnormal

                            
                            beq $s7, 1, menu_loop   # If the end of the file is reached, return to the menu
                            j cheack_file_IDs_unnormal       # Continue to check file IDs							
                                                        
                                    
                    
            BGT_test_unnormal:

                           lwc1 $f3, lowerBoundBGT # Load the lower bound value is 70.0
                           lwc1 $f4, upperBoundBGT # Load the upper bound value is 99.0

                           c.lt.s $f1, $f3         # Compare the test result in $f1 with the lower bound $f3
                           bc1t printIfUnnormal   # If the test result is less than the lower bound, branch to if_it_unnormal

                           c.le.s $f4, $f1         # Compare the test result in $f1 with the upper bound $f4
                           bc1t printIfUnnormal   # If the test result is greater than the upper bound, branch to if_it_unnormal
                           

                           beq $s7, 1, menu_loop
                           j  cheack_file_IDs_unnormal                                        

            LDL_test_unnormal:

 
                            lwc1 $f4, upperBoundLDL  # Load the upper bound value of 100.0 into $f3
                            c.le.s $f4, $f1          # Compare the test result in $f1 with the upper bound in $f3
                            bc1t printIfUnnormal    # If $f1 is not less than or equal to $f3 (i.e., $f1 is greater than $f3), branch to end_findNextLine
                           
                            beq $s7, 1, menu_loop
                            j  cheack_file_IDs_unnormal         
                        		
            BPT_test_unnormal: 

                            lwc1 $f4, upperBoundSystolicBPT # Load the upper bound value is 120.0
                            lwc1 $f3, upperBoundDiastolicBPT # Load the upper bound value is 80.0

                            c.le.s $f3 , $f2             # Compare the test result in $f1 with the lower bound $f3
                            bc1t printIfUnnormal   # If the test result is less than the lower bound, branch to if_it_unnormal

                            c.le.s $f4, $f1         # Compare the test result in $f1 with the upper bound $f4
                            bc1t printIfUnnormal   # If the test result is greater than the upper bound, branch to if_it_unnormal


                            beq $s7, 1, menu_loop
                            j  cheack_file_IDs_unnormal



              printIfUnnormal:
                  
                            move $a0, $t9           # Load the address of the start of the line into $a0
                            jal printLine             # Jump to printLine to print the data for this line
                            
                            beq $s7, 1, menu_loop   # If the end of the file is reached, return to the menu
                            j cheack_file_IDs_unnormal       # Continue to check file IDs			

                                    


    j menu_loop


retrieve_all_tests_in_period:


 	         #-------------Prompt user for the test ID---------------
   		 li $v0, 4
   		 la $a0, inputPrompt
   		 syscall

   		 # Read the test ID as a string
    		li $v0, 8
   		la $a0, inputBuffer_ID
  		li $a1, 20
  		  syscall
 	       #-------------end Prompt user for the test ID---------------
 	       
 	       
                #----------------enter the first date---------------------- 
                # Prompt user for the first year
                li $v0, 4
                la $a0, year_prompt
                syscall

                # Read integer input for the first year from user
                li $v0, 5
                syscall
                sw $v0, first_year        # Store the first year in memory

                # Prompt user for the first month
                li $v0, 4
                la $a0, month_prompt
                syscall

                # Read integer input for the first month from user
                li $v0, 5
                syscall
                sw $v0, first_month       # Store the first month in memory

                #----------------end of enter the first date-------------------


                #----------------enter the second date---------------------- 
                # Prompt user for the second year
                li $v0, 4
                la $a0, year_prompt2
                syscall

                # Read integer input for the second year from user
                li $v0, 5
                syscall
                sw $v0, second_year       # Store the second year in memory

                # Prompt user for the second month
                li $v0, 4
                la $a0, month_prompt2
                syscall

                # Read integer input for the second month from user
                li $v0, 5
                syscall
                sw $v0, second_month      # Store the second month in memory

                #----------------end of enter the second date-------------------

                #load the buffer address
                la $a0, buffer # Load the address of the buffer into $a0
                li $s7, 0 # Initialize the flag to 0
		

            check_file_IDs_period:

                move $t9, $a0 # Save the address of the start of the buffer in $t7

                jal BoolIDCheck  # f(a0 ,inputBuffer_ID) return equal if t5=1 else not.

                #if the t5 = 1 mean the ID is equal to the patient_id_period
                #else the ID is not equal to the patient_id_period

                beq $t5, 1, check_test_result_period
                jal get_next_line
                beq $s7, 1, menu_loop
                j check_file_IDs_period



            check_test_result_period:
                
                    move $a0, $t9          # Load the address of the start of the line into $a0
                    jal LineYearMonthExtraction # f(a0) will return the year and month of the test result in t6 and t7

                    lw $s0, first_year                # Load the start year
                    lw $s1, first_month               # Load the start month
                    lw $s2, second_year               # Load the end year
                    lw $s3, second_month              # Load the end month

                    # Compare year first
                    slt $t0, $t6, $s0                 # $t0 = 1 if test year is less than start year
                    bne $t0, $zero, skip_print        # Skip printing if test year is less than start year

                    slt $t0, $s2, $t6                 # $t0 = 1 if end year is less than test year
                    bne $t0, $zero, skip_print        # Skip printing if test year is greater than end year

                    # If years are equal, check months
                    beq $t6, $s0, check_month_lower   # Branch to check if start month is valid
                    beq $t6, $s2, check_month_upper   # Branch to check if end month is valid

                    # Print the line if year is within range and month check is not needed
                    j print_line_valid_year_month

                check_month_lower:
                    slt $t0, $t7, $s1                 # $t0 = 1 if test month is less than start month
                    bne $t0, $zero, skip_print        # Skip printing if test month is less than start month
                    j print_line_valid_year_month

                check_month_upper:
                    slt $t0, $s3, $t7                 # $t0 = 1 if end month is less than test month
                    bne $t0, $zero, skip_print        # Skip printing if test month is greater than end month
                    j print_line_valid_year_month


                print_line_valid_year_month:

                    move $a0, $t9                     # Load the address of the start of the line into $a0
                    jal printLine                     # Function to print the line if it's within the date range
                    beq $s7, 1, menu_loop             # If the end of the file is reached, return to the menu
                    j check_file_IDs_period           # Continue to check file IDs

                skip_print:
                    jal get_next_line
                    beq $s7, 1, menu_loop
                    j check_file_IDs_period
        

    j  menu_loop

search_unnormal_tests_by_input_test :



                #-----------------------------------Selecting the test name--------------------------------
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
                    beq $t0, $t1, hemoglobin_label_test_value_unnormal

                    li $t1, 2
                    beq $t0, $t1, blood_glucose_test_label_test_value_unnormal

                    li $t1, 3
                    beq $t0, $t1, ldl_cholesterol_label_test_value_unnormal

                    li $t1, 4
                    beq $t0, $t1, blood_pressure_test_label_test_value_unnormal

                  
                    # If invalid option, show error and go back to menu
                    li $v0, 4
                    la $a0, promptInvalid
                    syscall
                    j search_unnormal_tests_by_input_test

                    # load the valu of each test name in user_test_new_value

                    hemoglobin_label_test_value_unnormal:
                    li $t1, 0x111        # ASCII sum for "Hgb"
                    sw $t1, user_test_new_value
                    j goto_date_unnormal
                          
                    
                    blood_glucose_test_label_test_value_unnormal:
                    li $t1, 0xDD         # ASCII sum for "BGT"
                    sw $t1, user_test_new_value
                    j goto_date_unnormal
                           
                    ldl_cholesterol_label_test_value_unnormal: 
                    li $t1, 0xDC         # ASCII sum for "LDL"
                    sw $t1, user_test_new_value
                    j goto_date_unnormal
                    
                    blood_pressure_test_label_test_value_unnormal:
                    li $t1, 0xE6         # ASCII sum for "BPT"
                    sw $t1, user_test_new_value
                          
               goto_date_unnormal: 
                   
                #load the buffer address
                la $a0, buffer # Load the address of the buffer into $a0
                li $s7, 0 # Initialize the flag to 0
		

            check_file_test_name_unnormal:

                 move $t9, $a0 # Save the address of the start of the buffer in $t7
                
                 li $t5, 0 # reset the value of t5 to 0
                 jal boolTestNameCheck # f(a0 , user_test_new_value) return equal if t5=1 else not.
                 beq $t5, 1, printResult_line_if_unnormal # if t5 = 0 mean the test name is not equal to the user_test_new_value if t5 = 1 mean the test name is equal to the user_test_new_value


	 	         move $a0, $t9
                 jal get_next_line
                 beq $s7, 1, check_founded_test_name_unnormal
                 j check_file_test_name_unnormal



            printResult_line_if_unnormal:
               
    
            move $a0, $t9          # Load the address of the start of the line into $a0
            jal line_test_values # f(a0) retrun F1 = test result in floating point, t4 = type of test, a0 = start of the next line

            #-----------------------------------sum the values of the test result to calculate the average--------------------------------
            
            beq $t4, 1, Hgb_test_unnormal_test_name
            beq $t4, 2, BGT_test_unnormal_test_name
            beq $t4, 3, LDL_test_unnormal_test_name
            beq $t4, 4, BPT_test_unnormal_test_name


            Hgb_test_unnormal_test_name:

                            lwc1 $f3, lowerBoundHgb # Load the lower bound value, which is 13.8
                            lwc1 $f4, upperBoundHgb # Load the upper bound value, which is 17.2

                            c.lt.s $f1, $f3         # Compare the test result in $f1 with the lower bound $f3
                            bc1t printIfUnnormalByTestName   # If the test result is less than the lower bound, branch to if_it_unnormal

                            c.le.s $f4, $f1         # Compare the test result in $f1 with the upper bound $f4
                            bc1t printIfUnnormalByTestName   # If the test result is greater than the upper bound, branch to if_it_unnormal

                            
                            beq $s7, 1, check_founded_test_name_unnormal  # If the end of the file is reached, return to the menu
                            j check_file_test_name_unnormal       # Continue to check file IDs							
                                                        
                                    
                    
            BGT_test_unnormal_test_name:

                           lwc1 $f3, lowerBoundBGT # Load the lower bound value is 70.0
                           lwc1 $f4, upperBoundBGT # Load the upper bound value is 99.0

                           c.lt.s $f1, $f3         # Compare the test result in $f1 with the lower bound $f3
                           bc1t printIfUnnormalByTestName   # If the test result is less than the lower bound, branch to if_it_unnormal

                           c.le.s $f4, $f1         # Compare the test result in $f1 with the upper bound $f4
                           bc1t printIfUnnormalByTestName   # If the test result is greater than the upper bound, branch to if_it_unnormal
                           

                           beq $s7, 1, check_founded_test_name_unnormal
                           j  check_file_test_name_unnormal                                        

            LDL_test_unnormal_test_name:

 
                            lwc1 $f4, upperBoundLDL  # Load the upper bound value of 100.0 into $f3
                            c.le.s $f4, $f1          # Compare the test result in $f1 with the upper bound in $f3
                            bc1t printIfUnnormalByTestName    # If $f1 is not less than or equal to $f3 (i.e., $f1 is greater than $f3), branch to end_findNextLine
                           
                            beq $s7, 1, check_founded_test_name_unnormal
                            j  check_file_test_name_unnormal         
                        		
            BPT_test_unnormal_test_name: 

                            lwc1 $f4, upperBoundSystolicBPT # Load the upper bound value is 120.0
                            lwc1 $f3, upperBoundDiastolicBPT # Load the upper bound value is 80.0

                            c.le.s $f3 , $f2        # Compare the test result in $f1 with the lower bound $f3
                            bc1t printIfUnnormalByTestName   # If the test result is less than the lower bound, branch to if_it_unnormal

                            c.le.s $f4, $f1         # Compare the test result in $f1 with the upper bound $f4
                            bc1t printIfUnnormalByTestName   # If the test result is greater than the upper bound, branch to if_it_unnormal


                            beq $s7, 1,check_founded_test_name_unnormal
                            j  check_file_test_name_unnormal

              printIfUnnormalByTestName:

                                                    #store in bool_found the value 1 to indicate that the test result is found
                            li $t1, 1
                            sw $t1, bool_found

                            move $a0, $t9           # Load the address of the start of the line into $a0
                            jal printLine             # Jump to printLine to print the data for this line
                            
                            beq $s7, 1, menu_loop   # If the end of the file is reached, return to the menu
                            j check_file_test_name_unnormal       # Continue to check file IDs			



    
        check_founded_test_name_unnormal:

            #if the bool_found = 1 mean the test result is found and updated
            #else the test result is not found and not updated

            lw $t1, bool_found
            beq $t1, 1, test_result_unnormal_by_test_name

            #if not found the record for update the test result print the message

            #print new line character

            li $v0, 11          # System call for printing a character
            li $a0, 10          # Load ASCII value of newline ('\n') into $a0
            syscall


            li $v0, 4
            la $a0, not_found_recorde
            syscall

            li $v0, 11          # System call for printing a character
            li $a0, 10          # Load ASCII value of newline ('\n') into $a0
            syscall

            j menu_loop

            
      
        test_result_unnormal_by_test_name:

                li $v0, 11          # System call for printing a character
                li $a0, 10          # Load ASCII value of newline ('\n') into $a0
                syscall        
                
                li $v0, 4
                la $a0, found_unnormal_test
                syscall

                li $v0, 11          # System call for printing a character
                li $a0, 10          # Load ASCII value of newline ('\n') into $a0
                syscall

                #reset the value of bool_found to 0
                li $t1, 0
                sw $t1, bool_found

                j menu_loop
        



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


#-----------------------------------Getting the floating-point values from the file--------------------------------

    la $a0, buffer         # Load address of the start of the buffer into $a0
    la $t7, buffer         # Initialize $t7 with the start of the buffer
    la $a1, outputString   # Load address of the output string into $a1




#line_test_values: 

# this function retrun the float value of the test result in F1 and the type of the test in t4
#and also a0 will be the start of the next line. if there no next line 


#example 
# 1200105:LDL, 2002-22, 6.0 line 

# F(a0)  Return --> F1 = 6.0 (float point) , t4 = 3 (type of test = LDL) , a0 = start of the next line
# s1 = 0, s2 = 0, s3 = 1, s4 = 0 (count of each test result) in the buffer   
# s7 = 0 means a0 has new line address and the buffer not end , s7 = 1 means the buffer end. and no more lines.

# t4 = 1 means Hgb, t4 = 2 means BGT, t4 = 3 means LDL, t4 = 4 means BPT
# s1 = count of Hgp, s2 = count of BGT, s3 = count of LDL, s4 = count of BPT  ,in the buffer


   get_values_from_line:

            jal line_test_values # Jump to the line_test_values label

            #-----------------------------------sum the values of the test result to calculate the average--------------------------------

            beq $t4, 1, Hgb_test_sum
            beq $t4, 2, BGT_test_sum
            beq $t4, 3, LDL_test_sum
            beq $t4, 4, BPT_test_sum

            Hgb_test_sum:
                        add.s $f20, $f20, $f1 
                         beq $s7, 1, find_the_avg  # if s7 = 1 mean done file reading
                        j get_values_from_line

            BGT_test_sum:
                        add.s $f21, $f21, $f1
                         beq $s7, 1, find_the_avg  # if s7 = 1 mean done file reading
			            j get_values_from_line            


            LDL_test_sum:
                        add.s $f22, $f22, $f1
                         beq $s7, 1, find_the_avg  # if s7 = 1 mean done file reading
                        j get_values_from_line	
                        		
            BPT_test_sum: 
                        add.s $f23, $f23, $f1
                        add.s $f24, $f24, $f2
                         beq $s7, 1, find_the_avg  # if s7 = 1 mean done file reading
                        j get_values_from_line


#-----------------------------------End of sum the values of the test result to calculate the average--------------------------

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
            mtc1 $s4, $f16  # Convert BPT count to floating-point
            cvt.s.w $f16, $f16

            # Divide sum by count to find the average
            div.s $f12, $f20, $f12  # Average for Hgb
            div.s $f13, $f21, $f13  # Average for BGT
            div.s $f14, $f22, $f14  # Average for LDL
            div.s $f15, $f23, $f15  # Average for BPT
            div.s $f16, $f24, $f16  # Average for BPT
            
            
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

            #print space and \ 
            li $v0, 11          # System call for printing a character
            li $a0, 32          # Load ASCII value of space (' ') into $a0
            syscall

            li $v0, 11          # System call for printing a character
            li $a0, 92          # Load ASCII value of backslash ('\') into $a0
            syscall
    
            mov.s $f12, $f16  # Load average BPT for printing
            li $v0, 2         # Print float
            syscall
            
                  # Print newline character
   	         li $v0, 11          # System call for printing a character
             li $a0, 10          # Load ASCII value of newline ('\n') into $a0
             syscall 


            j menu_loop
               

#----------------------------------------------end of get average test value-----------------------------------------------

delete_test:

li $s6 , 1


update_existing_test_result:

 

                #---------------Prompt user for the test ID---------------
                li $v0, 4
                la $a0, inputPrompt
                syscall

                # Read the test ID as a string
                    li $v0, 8
                la $a0, inputBuffer_ID
                li $a1, 20
                syscall
                #-------------end Prompt user for the test ID---------------
 	       
 	       


                #-----------------------------------Selecting the test name--------------------------------
                not_valid_choice:
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
                    beq $t0, $t1, hemoglobin_label_test_value

                    li $t1, 2
                    beq $t0, $t1, blood_glucose_test_label_test_value

                    li $t1, 3
                    beq $t0, $t1, ldl_cholesterol_label_test_value

                    li $t1, 4
                    beq $t0, $t1, blood_pressure_test_label_test_value

                  
                    # If invalid option, show error and go back to menu
                    li $v0, 4
                    la $a0, promptInvalid
                    syscall
                    j test_name

                    # load the valu of each test name in user_test_new_value

                    hemoglobin_label_test_value:
                    li $t1, 0x111        # ASCII sum for "Hgb"
                    sw $t1, user_test_new_value
                    j goto_date
                          
                    
                    blood_glucose_test_label_test_value:
                    li $t1, 0xDD         # ASCII sum for "BGT"
                    sw $t1, user_test_new_value
                    j goto_date
                           
                    ldl_cholesterol_label_test_value: 
                    li $t1, 0xDC         # ASCII sum for "LDL"
                    sw $t1, user_test_new_value
                    j goto_date
                    
                    blood_pressure_test_label_test_value:
                    li $t1, 0xE6         # ASCII sum for "BPT"
                    sw $t1, user_test_new_value
                          
                goto_date: 
                #----------------enter the first date---------------------- 
                # Prompt user for the first year
                li $v0, 4
                la $a0, year_prompt
                syscall

                # Read integer input for the first year from user
                li $v0, 5
                syscall
                sw $v0, first_year        # Store the first year in memory

                # Prompt user for the first month
                li $v0, 4
                la $a0, month_prompt
                syscall

                # Read integer input for the first month from user
                li $v0, 5
                syscall
                sw $v0, first_month       # Store the first month in memory

                #----------------end of enter the first date-------------------

                     
    
                #load the buffer address
                la $a0, buffer # Load the address of the buffer into $a0
                li $s7, 0 # Initialize the flag to 0
		

            check_file_IDs_Update:

                move $t9, $a0 # Save the address of the start of the buffer in $t7

                jal BoolIDCheck  # f(a0 ,inputBuffer_ID) return equal if t5=1 else not.

                #if the t5 = 1 mean the ID is equal to the patient_id_period
                #else the ID is not equal to the patient_id_period

                beq $t5, 1, check_test_result_update
                jal get_next_line
                beq $s7, 1, check_founded_bool_update
                j check_file_IDs_Update



            check_test_result_update:
                
                    move $a0, $t9          # Load the address of the start of the line into $a0
                    jal LineYearMonthExtraction # f(a0) will return the year and month of the test result in t6 and t7

                    lw $s0, first_year                # Load the start year
                    lw $s1, first_month               # Load the start month
                    
                    bne $t6, $s0, skip_edit
                    bne $t7, $s1, skip_edit

                
                    move $a0, $t9          # Load the address of the start of the line into $a0
                    li $t5, 0 # reset the value of t5 to 0
                    jal boolTestNameCheck # f(a0 , user_test_new_value) return equal if t5=1 else not.
                    bne $t5, 1, skip_edit # if t5 = 0 mean the test name is not equal to the user_test_new_value if t5 = 1 mean the test name is equal to the user_test_new_value

                    #store in bool_found the value 1 to indicate that the test result is found
                    li $t1, 1
                    sw $t1, bool_found

                    #-----------------Prompt user for the new test result----------------------

                    # if S6 = 1, skip this part , beacause the user want to delete the test result

                    beq $s6, 1, skip_edit # for delete the test result
                    

                    # Prompt the user for input
                    li $v0, 4                  # Syscall for print string
                    la $a0, promptTestResult             # Address of prompt string
                    syscall


                    li $v0, 8                  # Syscall code for reading a string
                    la $a0, floatBuffer       # Address of buffer to store the string
                    li $a1, 20                # The maximum number of characters to read
                    syscall

                    # change the value of the test result in the buffer

                    skip_edit:

                    move $a0,$t9  # Load the address of the start of the line into $a0
                    jal update_test_resultInLine

                   

        check_founded_bool_update:

            #if the bool_found = 1 mean the test result is found and updated
            #else the test result is not found and not updated

            lw $t1, bool_found
            beq $t1, 1, test_result_updated

            #if not found the record for update the test result print the message

            #print new line character

            li $v0, 11          # System call for printing a character
            li $a0, 10          # Load ASCII value of newline ('\n') into $a0
            syscall


            li $v0, 4
            la $a0, not_found_recorde
            syscall

            li $v0, 11          # System call for printing a character
            li $a0, 10          # Load ASCII value of newline ('\n') into $a0
            syscall

            j menu_loop

            
      
        test_result_updated:


                li $v0, 11          # System call for printing a character
                li $a0, 10          # Load ASCII value of newline ('\n') into $a0
                syscall


                beq $s6, 1, promt_delete # if s6 = 1 mean the user want to delete the test result

                li $v0, 4
                la $a0, test_result_updated_promt
                syscall

                promt_delete: 

                li $v0, 4
                la $a0, test_result_deleted_promt
                syscall


                li $v0, 11          # System call for printing a character
                li $a0, 10          # Load ASCII value of newline ('\n') into $a0
                syscall

                #reset the value of bool_found to 0
                li $t1, 0
                li $s6, 0
                sw $t1, bool_found

                j menu_loop
        



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



#------------------------calculate the sum of the ASCII values in the inputBuffer_ID--------------
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


#-------------------------------------End of calculate the sum of the ASCII values in the inputBuffer_ID----------------


#-------------------------Function Return float in F1 also type of Test name for eachline as parameter in a0---------


#line_test_values: 

# this function retrun the float value of the test result in F1 and the type of the test in t4
#and also a0 will be the start of the next line. if there no next line 


#example 
# 1200105:LDL, 2002-22, 6.0 line 

# F(a0)  Return --> F1 = 6.0 (float point) , t4 = 3 (type of test = LDL) , a0 = start of the next line
# s1 = 0, s2 = 0, s3 = 1, s4 = 0 (count of each test result) in the buffer   
# s7 = 0 means a0 has new line address and the buffer not end , s7 = 1 means the buffer end. and no more lines.

# t4 = 1 means Hgb, t4 = 2 means BGT, t4 = 3 means LDL, t4 = 4 means BPT
# s1 = count of Hgp, s2 = count of BGT, s3 = count of LDL, s4 = count of BPT  ,in the buffer


line_test_values:

    la $a1, outputString   # Load address of the output string of testResult(string) into $a1  
    
    # .data section : outputString: .space 50  # Allocate space for the output string

    li $t2, 0 # rest the value of asscii sum.

    move $t8, $ra # save the return address


find_semicolon:

    lb $t0, 0($a0)        # Load the next character from the input string into $t0
    beq $t0, ':', determine_test_name # If colon, check if ID matches
    li $t1, ','           # Load the ASCII value of semicolon into $t1
    beq $t0, $t1, increment_counter # If the current character is a semicolon, increment the counter
    addiu $a0, $a0, 1     # Move to the next character in the input string
    j find_semicolon      # Jump back to the start of the loop

increment_counter:
    addiu $t2, $t2, 1     # Increment the semicolon counter
    addiu $a0, $a0, 1     # Move past the semicolon
    li $t3, 2             # We're looking for the second semicolon
    beq $t2, $t3, start_copying # If we've found two semicolons, start copying
    j find_semicolon      # Otherwise, keep looking for semicolons

start_copying:

    lb $t0, 0($a0)        # Load the next character from the input string into $t0
    beq $t0, ' ', skipSpace # Check for the space character
    beq $t0, '\n', ReturnValues # Check for the end of the line
    sb $t0, 0($a1)        # Store the character in the output string
    beq $t0, '/', BPT_handel # If backslash, jump to BPT_handel
    addiu $a0, $a0, 1     # Move to the next character in the input string
    addiu $a1, $a1, 1     # Move to the next position in the output string
    j start_copying       # Jump back to the start of the copy loop

skipSpace:
    addiu $a0, $a0, 1     # Move to the next character in the input string
   j start_copying

   BPT_handel: 
             # just add \n to this byte where \ is exist
                li $t1, 0x0a          # ASCII value of '\n'
                sb $t1, 0($a1)        # Add a '\n' to the output string
                addiu $a0, $a0, 1     # Move to the next character in the input string
                la $a1, outputString2    
                j start_copying



# -----------------------------------Get return uniqe value in t4 according to the test name-------------------------------- 


 determine_test_name: 
  li $t3, 0 # rest the value of asscii sum. 

 GetUniqeValueOfTestName:

  addiu $a0, $a0, 1      # Skip the : character
  lb $t0, 0($a0)        # Load the next character from the input string into $t0
  beq $t0, ' ', GetUniqeValueOfTestName # Check for the end of the string
  
  # sum the ascii values of the test name to choose the test value to calculate the average
    beq $t0, ',', get_type_of_test # If colon, have unique value for each test name 
    addu $t3, $t3, $t0     # Add the ASCII value to the sum for test name comparison
    
    jal GetUniqeValueOfTestName

get_type_of_test:

    addiu $t2, $t2, 1     # Increment the semicolon counter

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


ReturnValues:
      
            move $t7, $a0          # save the start of the next line
            sb $t0, 0($a1)        # Store \n in the output string for use it for termination
            
            li $t2,0 # rest the value of t2 to 0  for string2. 


            #loop to check outupt string if it has dot or not

          la $a0, outputString
          check_dot:
                    lb $t0, 0($a0)        # Load the next character from the output string into $t0
                    beq $t0, '.', dot_found # If dot, jump to dot_found
                    beq $t0, '\n', no_dot_found # If newline, jump to no_dot_found
                    addiu $a0, $a0, 1      # Move to the next character in the output string
                    j check_dot            # Jump back to the start of the loop

          no_dot_found:
                    li $t1, 0x2E          # ASCII value of '.'
                    sb $t1, 0($a0)        # Add a decimal point to the end of the output string
                    addiu $a0, $a0, 1     # Move to the next position in the output string
                    # add zero value after the decimal point
                    li $t1, 0x30          # ASCII value of '0'
                    sb $t1, 0($a0)        # Add a zero after the decimal point
                    addiu $a0, $a0, 1     # Move to the next position in the output string
                    # add \n value after the decimal point
                    li $t1, 0x0A          # ASCII value of '\n'
                    sb $t1, 0($a0)        # Add a newline character after the decimal point
                   
  
         dot_found:  
                     bne $t4, 4, skip_this_no_need
                     beq $t2, 1, skip_this_no_need  

                     # use t2 for terminate the string2 
                     #store in t2 the value 1  to not make the loop to check the dot again
                        li $t2, 1
                        la $a0, outputString2   # Load address of the output string into $a0
                        j check_dot 


            skip_this_no_need:

	   
            beq $t4, 1, Hgb_test_type
            beq $t4, 2, BGT_test_type
            beq $t4, 3, LDL_test_type
            beq $t4, 4, BPT_test_type

            Hgb_test_type:
                        la $a0, outputString   # Load address of the output string into $a0
                        jal parseString        # Jump to the string parsing function
                        jal convertPartsToFloatAndPrint
                        # f1 will have the float value of the test result
                        j doneConvertion


            BGT_test_type:
                        la $a0, outputString   # Load address of the output string into $a0
                        jal parseString        # Jump to the string parsing function
                        jal convertPartsToFloatAndPrint
                        # f1 will have the float value of the test result
			            j doneConvertion            


            LDL_test_type:
                        la $a0, outputString   # Load address of the output string into $a0
                        jal parseString        # Jump to the string parsing function
                        jal convertPartsToFloatAndPrint
                        # f1 will have the float value of the test result
                        j doneConvertion	
                        		
            BPT_test_type: 
                        la $a0, outputString   # Load address of the output string into $a0
                        jal parseString        # Jump to the string parsing function
                        jal convertPartsToFloatAndPrint
                        mov.s $f4 , $f1

                        la $a0, outputString2   # Load address of the output string into $a0
                        jal parseString        # Jump to the string parsing function
                        jal convertPartsToFloatAndPrint
                        
                        mov.s $f2 , $f1
                        mov.s  $f1 , $f4
                        # f1 will have the float value of the test result


doneConvertion:

                move $ra, $t8 # restore the return address
                addiu $t7, $t7, 1 # Move to the next line 
                move $a0, $t7    # Move to the next line stored in a0 as return value
                li $t2, 0              # Reset the sum for next ID
                lb $a1, 0($a0)
                beq $a1, '\0', buffer_done # Check for end of buffer
                li $s7, 0 # set the value of s6 to 0 to indicate that the buffer is not done.
                jr $ra

                buffer_done:
                li $s7, 1 # set the value of s6 to 1 to indicate that the buffer is done
                jr $ra
               


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
    beq $t0, '\0', no_value
    sub $t0, $t0, '0'     # Convert from ASCII to integer
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
    
    no_value:
    
    jr $ra                 # Return
	
#---------------------------------------End of string to float conversion--------------------------------------------

#---------------------------------------End of Function which returns the type of the test--------------




#---------------------------------------Check Id is equal to the inputBuffer_ID-------------------------

BoolIDCheck:

# f(a0, inputbuffer ) Return --> in t5 = 1 if the ID is equal to the inputBuffer_ID, 0 otherwise
# a0 for the line .

    move $t8, $ra # save the return address

    move $t7 , $a0 # save the address of the line in t7

    # Search for the test ID in the buffer
  
 # Initialize $t3 with 0 for summing ASCII values of inputBuffer_ID
    li $t3, 0
    la $a0, inputBuffer_ID
    jal calculateSum       # Calculate sum of ASCII values in inputBuffer_ID
    move $t5, $v0          # Move result to $t5



    move $a0, $t7 # restore the address of the line in a0
    # Reset $t3 to 0 for use in comparing with each ID in buffer
    li $t3, 0

findIdInline:

    lb $a1, 0($a0)         # Load the byte at the current buffer position into $a1
    beq $a1, '\0', doneNoIDINfile             # If colon, check if ID matches
    beq $a1, ':', checkIdIfEqual              # If colon, check if ID matches
    addiu $a0, $a0, 1      # Move to the next character in buffer
    addu $t3, $t3, $a1     # Add the ASCII value to the sum for ID comparison
    j findIdInline

checkIdIfEqual:
    beq $t5, $t3, values_equal_OF_IDS # Compare sum of ASCII values
    # If not equal, find the start of the next line
        li $t5, 0
        move $ra, $t8 # restore the return address
        jr $ra


values_equal_OF_IDS :
    # If the ID is equal, return 1
    li $t5, 1
    move $ra, $t8 # restore the return address
    jr $ra

doneNoIDINfile:
    li $s7 , 1 # set the value of s7 to 1 to indicate that the buffer is done.
    li $t5, 0
    move $ra, $t8 # restore the return address
    jr $ra

#---------------------------------------End of Check Id is equal to the inputBuffer_ID------------------



#---------------------------------------file Functions area--------------------------------------------


#-----------------------------------function to read file--------------------------------------------

openReadFile:


    la $a0, buffer        # Load the address of the buffer into $a0
    li $t0, 0             # Initialize $t0 to 0 (the value to set each byte of the buffer)
    li $t1, 5          # Set $t1 to the size of the buffer

    
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

   # Close the file
    li $v0, 16               # sys_close
    move $a0, $s6            # File descriptor
    syscall

    jr $ra


error_open:
    li $v0, 4                # sys_write (print_string)
    la $a0, error_msg        # Pointer to the error message
    syscall

    li $v0, 10               # sys_exit
    syscall


j menu_loop


#writing new buffer to the file

writeBufferToFile:

            #count for number of bytes written in buffer

                    la $a0, buffer           # Load the address of the buffer into $a0
                    li $t1, 0                # Initialize the byte count to 0

                    count_loop:
                        lb $t0, 0($a0)        # Load the next byte from the buffer into $t0
                        beq $t0, '\0', done_counting # If null terminator, we're done
                        addiu $t1, $t1, 1      # Increment the byte count
                        addiu $a0, $a0, 1      # Move to the next byte
                        j count_loop           # Repeat the loop

                    done_counting:

                    move $t2, $t1            # Save the number of bytes in $t2


            # Open the file for writing (create if not exists, truncate if exists)
                li $v0, 13               # System call for open file
                la $a0, filename         # Address of the filename to open
                li $a1, 1             # Flags for writing (0x001 | 0x200 | 0x040: create, truncate, write
                syscall
                move $s1, $v0            # Save the file descriptor in $s6

                # Check for a valid file descriptor
                bltz $s1, handle_error   # If $s6 is negative, an error occurred during file opening

                # Write the buffer to the file
                li $v0, 15               # System call for write to file
                move $a0, $s1            # File descriptor
                la $a1, buffer           # Address of buffer containing data
                move $a2, $t2              # Number of bytes to write from buffer
                syscall
                move $t1, $v0            # Save the number of bytes written to $t1

                # Check if the file write was successful
                bltz $t1, handle_error   # If $t1 is negative, an error occurred during file write

                # Close the file
                li $v0, 16               # System call for close file
                move $a0, $s1            # File descriptor to close
                syscall

                jr $ra

            handle_error:
                li $v0, 10               # Exit program
                syscall

#-----------------------------------End of function to read file--------------------------------------------



#-----------------------------------function to print the line of the file--------------------------------

#print the line of the file

printLine:

    # f(a0) -> print line also t9 has the address of next line with a0 
    	
    lb $a1, 0($a0)
    beq $a1, '\n', donePrintingLine  # End of data for this line
    beq $a1, '\0', noNextLIne  # End of data for this line
    move $a0, $a1
    li $v0, 11             # syscall for printing character
    syscall
    
    addiu $t9, $t9, 1      # Move to the next character in buffer
    move $a0, $t9          # Load the address of the start of the line into $a0
   
    j printLine            # Continue printing data
    
donePrintingLine:

    move $a0, $a1
   	li $v0, 11             # syscall for printing character
   	syscall
   	
        addiu $t9, $t9, 1      # Move to the next character in buffer
        move $a0, $t9          # Load the address of the start of the line into $a0
        lb $a1, 0($a0)
        beq $a1, '\0', doneFile  # End of data for this line

        jr $ra

doneFile:
    li $s7 , 1 # set the value of s7 to 1 to indicate that the buffer is done.
    jr $ra



#-----------------------------------End of function to print the line of the file---------------------------
    
        
#-----------------------------------function to get the next line--------------------------------------------      
   
get_next_line:
    # f(a0) return --> in a0 the start of the next line , s7 = 1 if the buffer is done, 0 otherwise

    lb $a1 , 0($a0) # Load the next character from the buffer into $a1
    beq $a1, '\0', noNextLIne  # End of data for this line
    beq $a1, '\n', done_get_next_line  # End of data for this line
    addiu $a0, $a0, 1      # Move to the next character in buffer
    j get_next_line         # Continue printing data

   done_get_next_line: 
    addiu $a0, $a0, 1      # Move to the next line
    lb $a1 , 0($a0) # Load the next character from the buffer into $a1
    beq $a1, '\0', noNextLIne  # End of data for this line
    jr $ra

    noNextLIne:
    li $s7 , 1 # set the value of s7 to 1 to indicate that the buffer is done.
    jr $ra


#-----------------------------------End of function to get the next line--------------------------------------------


#-----------------------------------function to extract year-month from the line------------------------------------

LineYearMonthExtraction:

#this funtion will take a0 and return the year and month in t6 and t7 respectively

#f(a0) return --> in t6 = year, t7 = month

#example :

# 1200105:LDL, 2002-22, 6.0 line

# f(a0)  Return --> t6 = 2002, t7 = 22 , a0 = end of month year (recommanded not to use it).

# the function will start from the first comma after the ID and will stop at the second comma 

move $t8, $ra # save the return address
li $t6, 0 # rest the value of year
li $t7, 0 # rest the value of month

find_commma_for_year_month:

    lb $t0, 0($a0)        # Load the next character from the input string into $t0
    beq $t0, ',', extract_year # If colon, check if ID matches
    addiu $a0, $a0, 1      # Move to the next character in the input string

    j find_commma_for_year_month      # Jump back to the start of the loop

extract_year:
    
        addiu $a0, $a0, 1      # Move to the next character in the input string
        lb $t0, 0($a0)        # Load the next character from the input string into $t0
        beq $t0, '-', extract_month # If - 
        beq $t0, ' ', extract_year # If newline, done parsing
        sub $t0, $t0, '0'      # Convert from ASCII to integer
        mul $t6, $t6, 10       # Multiply current result by 10
        add $t6, $t6, $t0      # Add the new digit

        j extract_year

extract_month:

    addiu $a0, $a0, 1      # Move to the next character in the input string
    lb $t0, 0($a0)        # Load the next character from the input string into $t0
    beq $t0, ',', done_extract_month # If comma, done parsing
    sub $t0, $t0, '0'      # Convert from ASCII to integer
    mul $t7, $t7, 10       # Multiply current result by 10
    add $t7, $t7, $t0      # Add the new digit

    j extract_month


done_extract_month: 

    move $ra, $t8 # restore the return address
    jr $ra

#-----------------------------------End of function to extract year-month from the line------------------------------------

#-----------------------------------update the test result in the buffer--------------------------------------------

update_test_resultInLine:




         li $t2, 0 # rest the value of asscii sum.
         move $t8, $ra # save the return address
         la $a1, floatBuffer # Load the address of the input string into $a1

           move $s0, $a0

            loop_find_end_of_line:
                                 
                lb $t0, 0($s0)        # Load the next character from the input string into $t0
                beq $t0, '\n', end_find_end_of_line # If newline, end of line
                addiu $s0, $s0, 1      # Move to the next character in the input string
                j loop_find_end_of_line      # Jump back to the start of the loop

                end_find_end_of_line:
                # save the end of this line address in end_target_line_address variable
                addiu $s0, $s0, 1
                sw $s0, end_target_line_address # store the start of the next line in the buffer

                jal copy_buffer # when we reach the end of main buffer line we copy the buffer for extend cases 
                # it returns in end_target_line_address the start of the next line of the copied buffer.


#-------------------------------------------------------------------------------

    beq $s6 , 1, skip_to_delete1 # here to delete the line in the buffer

#-------------------------------------------------------------------------------            

        find_semicolon_update:
             lb $t0, 0($a0)        # Load the next character from the input string into $t0
            li $t1, ','           # Load the ASCII value of semicolon into $t1
             beq $t0, $t1, increment_counter_update # If the current character is a semicolon, increment the counter
            addiu $a0, $a0, 1     # Move to the next character in the input string
            j find_semicolon_update      # Jump back to the start of the loop

         increment_counter_update:
            addiu $t2, $t2, 1     # Increment the semicolon counter
            addiu $a0, $a0, 1     # Move past the semicolon
            li $t3, 2             # We're looking for the second semicolon
            beq $t2, $t3, startUpdating # If we've found the second semicolon, start updating the value
            j find_semicolon_update      # Otherwise, keep looking for semicolons

            #this loop to find the end of the line of a0 and store it in end_target_line_address

       
     startUpdating:

                lb $t0, 0($a0)          # Load the next character from the input string into $t0
                lb $t1, 0($a1)          # Load the next character from the output string into $t1
                
                beq $t1, '\0', done_updating # If output character is newline, stop updating

                beq $t0, ' ', skipSpaceInBuffer # Skip input spaces
                beq $t1, ' ', skipSpaceInFloat # Skip output spaces

                sb $t1, 0($a0)            # Store the character from the output string into the input string
                addiu $a0, $a0, 1         # Move to the next character in the input string
                addiu $a1, $a1, 1         # Move to the next character in the output string
                j startUpdating           # Jump back to the start of the loop

            skipSpaceInBuffer:
                addiu $a0, $a0, 1         # Skip one space in the input buffer
                j startUpdating           # Return to the main loop

            skipSpaceInFloat:
                addiu $a1, $a1, 1         # Skip one space in the output buffer
                j startUpdating           # Return to the main loop

         
            done_updating:

                skip_to_delete1:

            
                sb $t1, 0($a0)           # Store the newline character in the buffer
                lw $s1, end_target_line_address

                # now we have the address of copied buffer in s1 and we want to paste it in a0 

                loop_paste_buffer:
                lb $t0, 0($s1)        # Load the next character from the buffer into $t0
                beq $t0, '\0', finish_paste_buffer # If null terminator, finish pasting
                sb $t0, 0($a0)        # Store the character in the buffer
                addiu $a0, $a0, 1     # Move to the next character in the buffer
                addiu $s1, $s1, 1     # Move to the next character in the copy_buffer
                j loop_paste_buffer   # Jump back to the start of the loop

                finish_paste_buffer:
                sb $t0, 0($a0)
                
                jal writeBufferToFile     # Function to write buffer to file
                move $ra, $t8             # restore the return address   
                jr $ra                    # return to the main function
                                                        # Return from the function


 #-----------------------------------End of update the test result in the buffer--------------------------------------------

 #-----------------------------------bool test name check--------------------------------------------

boolTestNameCheck:

            move $t8, $ra # save the return address

    
            #load the value of the test name to check user_test_new_value to s0

            find_semicolon_for_test_name_check:

                lb $t0, 0($a0)        # Load the next character from the input string into $t0
                beq $t0, '\0', no_line_to_check # Check for the end of the string
                beq $t0, ':', check_test_name # If colon, test name matche
                addiu $a0, $a0, 1     # Move to the next character in the input string
                j find_semicolon_for_test_name_check      # Jump back to the start of the loop


                check_test_name: 
                li $t3, 0 # rest the value of asscii sum. 

                get_asscii_sum_of_test_name:

                addiu $a0, $a0, 1      # Skip the : character
                lb $t0, 0($a0)        # Load the next character from the input string into $t0
                beq $t0, ' ', get_asscii_sum_of_test_name # Check for the end of the string
                
                # sum the ascii values of the test name to choose the test value to calculate the average
                beq $t0, ',', compare_test_name # If colon, have unique value for each test name 
                addu $t3, $t3, $t0     # Add the ASCII value to the sum for test name comparison
                    
                jal get_asscii_sum_of_test_name

                compare_test_name:

                    # Check the sum of the ASCII values to determine the test name
                    li $t1, 0x111        # ASCII sum for "Hgb"
                    beq $t3, $t1, Hgb_test_check # If the sum matches "Hgb", jump to Hgb_test

                    li $t1, 0xDD         #  ASCII sum for "BGT"
                    beq $t3, $t1, BGT_test_check # If the sum matches "BGT", jump to BGT_test

                    li $t1, 0xDC        #  ASCII sum for "LDL"
                    beq $t3, $t1, LDL_test_check # If the sum matches "LDL", jump to LDL_test

                    li $t1, 0xE6         #  ASCII sum for "BPT"
                    beq $t3, $t1, BPT_test_check # If the sum matches "BPT", jump to BPT_test

                #return unique value for each test name

                    Hgb_test_check:
                    la $a0, user_test_new_value   # Load address of the value of the test result into $a0
                    lw $s0 , 0($a0) # load the value of the test result to s0
                    # compare the test name with the user_test_new_value
                    #then return to ra in t8
                    beq $s0,$t1 , equal_test_name # If the test name matches the user_test_new_value, return 1

                    BGT_test_check:
                    la $a0, user_test_new_value   # Load address of the value of the test result into $a0
                    lw $s0 , 0($a0) # load the value of the test result to s0
                    beq $s0,$t1 , equal_test_name # If the test name matches the user_test_new_value, return 1
                  

                    LDL_test_check:
                    la $a0, user_test_new_value   # Load address of the value of the test result into $a0
                    lw $s0 , 0($a0) # load the value of the test result to s0
                    beq $s0,$t1 , equal_test_name # If the test name matches the user_test_new_value, return 1
                  
                    BPT_test_check:
                    la $a0, user_test_new_value   # Load address of the value of the test result into $a0
                    lw $s0 , 0($a0) # load the value of the test result to s0
                    beq $s0,$t1 , equal_test_name # If the test name matches the user_test_new_value, return 1


                    move $ra, $t8 # no match return 0
                    li $t5, 0
                    jr $ra
                    

                    equal_test_name:
                    li $t5, 1
                    move $ra, $t8 # restore the return addres
                    jr $ra

                    no_line_to_check:
                    li $t5, 0
                    move $ra, $t8 # restore the return addres
                    li $s7 , 1 # set the value of s7 to 1 to indicate that the buffer is done.
                    jr $ra
                    
   
#-----------------------------------copy buffer function-----------------------------------------------------

copy_buffer:

            #This function will copy the buffer to another buffer and save the address we want to continue the buffer from it.

            la $s0 , buffer # Load the address of the buffer into $s0
            la $s1 , buffer_temp # Load the address of the copy_buffer into $s1
            #load the value of end_target_line_address into s2
            lw $s2 , end_target_line_address

            copy_loopBuffer:
                lb $t0, 0($s0)        # Load the next character from the buffer into $t0
                beq $t0, '\0', done_copy # If null terminator, done copying
                beq $s0, $s2, save_for_copy_to_continue # If end of the line, save the address
                sb $t0, 0($s1)        # Store the character in the copy_buffer
                addiu $s0, $s0, 1     # Move to the next character in the buffer
                addiu $s1, $s1, 1     # Move to the next character in the copy_buffer
                j copy_loopBuffer           # Continue copying


                save_for_copy_to_continue:
                sw $s1, end_target_line_address
                sb $t0, 0($s1)        # Store the character in the copy_buffer
                addiu $s0, $s0, 1     # Move to the next character in the buffer
                addiu $s1, $s1, 1     # Move to the next character in the copy_buffer
                
                j copy_loopBuffer

            done_copy:
                jr $ra                # Return from the function

            



#-----------------------------------end copy buffer function--------------------------------------------------

#---------------------------------------End of file Functions area--------------------------------------------





#---------------------------------------Functions area--------------------------------------------        

end:
    # Exit program
    li $v0, 10
    syscall

