.data 
input_buffer: .space 1001 #Buffer for user input(1000 chars + Null)
substring_buf: .space 11   #10 chars plus null for processing
null_str: .asciiz "NULL" #Null output string 
semicolon: .asciiz ";"  #Seperator 

.text
.globl main

main:
    #Read input string
    li $v0, 8   #syscall 8 :read string
    la $a0, input_buffer #load buffer address
    li $a1, 1001 #read up to 1000 characters
    syscall

    #Calculate input length
    la $t0, input_buffer
    li $t1, 0  #Counter
find_length:
    lb $t2, 0($t0)
    beqz $t2, end_find_length #Null terminator
    li $t3, 10  #Check for new line
    beq $t2, $t3, replace_newline
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j find_length

replace_newline:
    sb $zero, 0($t0)  #Replace newline with null

end_find_length:
    addi $t3, $t1, 9
    divu $t3, $t3, 10 #$t3 = num_strings
    li $t5, 0 #Substring index 

process_substrings:
    bge $t5, $t3, exit_program #All substrings have been processed

    #Prepare substring 
    la $t6, substring_buf
    li $t7, 0      #Char counter (0-9)

fill_substring:
    bge $t7, 10, call_subprogram

    #Calculate position in input
    mul $t8, $t5, 10 #Substring start index
    add $t8, $t8, $t7 
    bge $t8, $t1, pad_space

    #Load from input
    la $t9, input_buffer
    add $t8, $t8, $t7 
    lb $t9, 0($t9)
    j store_char

pad_space:
    li $t9, ' '   #Pad with space

store_char:
    sb $t9, 0($t6)  #Store in substring buffer
    addi $t6, $t6, 1
    addi $t7, $t7, 1
    j fill_substring
call_subprogram:
    #Save registers
    addi $sp, $sp, -16
    sw $t3, 0($sp)
    sw $t5, 4($sp)
    sw $t1, 8($sp)
    sw $ra, 12($sp)
    
    la $a0, substring_buf
    jal get_substring_value

    #Restore registers
    lw $t3, 0($sp)
    lw $t5, 4($sp)
    lw $t1, 8($sp)
    lw $ra 12($sp)
    addi $sp, $sp, 16 

    #Handle result
    li $t0, 0x7FFFFFFF
    beq $v0, $t0, print_null

    move $a0, $v0  #Print integer result
    li $v0, 1
    syscall
    j check_separator
print_null:
    la $a0, null_str   #Print "NULL"
    li $v0, 4
    syscall
check_separator:
    addi $t5, $t5, 1     #Increment substring index
    beq $t5, $t3, process_substrings #Skip seperator if last

    la $a0, semicolon
    li $v0, 4
    syscall

    j process_substrings

exit_program:
    li $v0, 10      #Exit
    syscall 

    #Sub program: We need to get the substring value 
    #Input is $a0 address of the ten character substring 
    #Output $v0 G-H or 0x7FFFFFFFF
get_substring_value:
    #Save registers
    addi $sp, $sp, -16
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)

    li $s0, 0   #G sum
    li $s1, 0  #H sum
    li $s2, 0 #Char index(0-9)
    li $s3, 0 #Valid digit counter 



process_char:
    bge $s2, 10, end_processing  #Exit loop if i >= 10

    #Load current character
    lb $t0, 0($a0)

    #Check if character is a digit (0-9)

    li $t1, '0'   #'0' ASCII
    blt $t0, $t1, check_lower
    li $t1, '9'   #'9' ASCII
    bgt $t0, $t1, check_lower
    subu $t2, $t0, '0' #Converting the value to (0-9)
    j valid_digit

check_lower:
    #check lowercase a-z(ASCII 97-122)
    li $t1, 'a'
    blt $t0, $t1, check_upper
    li $t1, 'p'
    bgt $t0, $t1, check_upper
    subu $t2, $t0, 'a'   # c - 'a'
    addi $t2, $t2, 10 #value = 10 + (c-'a')
    j valid_digit 
check_upper:
    #Check uppercase A-Z(ASCII 65-91)
    li $t1, 'A'
    blt $t0, $t1, invalid
    li $t1, 'P'
    bgt $t0, $t1, invalid
    subu $t2, $t0, 'A' # c - 'A'
    addi $t2, $t2, 10 #value = 10 + (c- 'A')
    j valid_digit

invalid:
    addi $a0, $a0, 1 #Next character
    addi $s2, $s2, 1
    j process_char  #Skip invalid character 

valid_digit:
    addi $s3, $s3, 1 #increment valid counter
    blt $s2, 5, add_to_g
    add $s1, $s1, $t2  #Add to H 
    j next
add_to_g:
    add $s0, $s0, $t2  #Add to G
next:
    addi $a0, $a0, 1  #next char
    addi $s2, $s2, 1
    j process_char
end_processing:
    #Check if total sum is zero
    beqz $s3, return_null
    sub $v0, $s0, $s1   #G-H
    j epilogue

return_null:
    li $v0, 0x7FFFFFFF  #Return Null code
epilogue:
    #Restore registers
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    addi $sp, $sp, 16
    jr $ra