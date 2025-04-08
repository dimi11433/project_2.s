.data 
input_buffer: .space 1001 #Buffer for user input(1000 chars + Null)
substring_buff .space11   #10 chars plus null for processing
null_str: .asciiz "NULL" #Null output string 
semicolon: .asciiz ";"  #Seperator 

.text
.globl main

main:
    #Read input string
    li $v0, 8   #syscall 8 :read string
    la $a0, input_buffer #load buffer address
    li $a1, 11 #read up to 10 characters
    syscall

    #Initialize G and H sums
    li $s0, 0 #G = 0(first half sum)
    li $s1, 0 #H = 0(second half sum)

    li $t0, 0 #Loop counter(i = 0 to 9)

process_loop:
    bge $t0, 10, end_loop  #Exit loop if i >= 10

    #Load current character
    lb, $t2, input_buffer($t0)

    #Check if character is a digit (0-9)

    li $t3, 48   #'0' ASCII
    li $t4, 57   #'9' ASCII
    blt $t2, $t3, check_lower
    bgt $t2, $t4, check_lower
    sub $t5, $t2, $t3 #Converting the value to (0-9)
    j add_sum

check_lower:
    #check lowercase a-z(ASCII 97-122)
    li $t3, 97
    li $t4, 122
    blt $t2, $t3, check_upper
    bgt $t2, $t4, check_upper
    sub $t5, $t2, $t3   # c - 'a'
    addi $t5, $t5, 10 #value = 10 + (c-'a')
    j add_sum 
check_upper:
    #Check uppercase A-Z(ASCII 65-91)
    li $t3, 65
    li $t4, 91
    blt $t2, $t3, invalid_char
    bgt $t2, $t4, invalid_char
    sub $t5, $t2, $t3 # c - 'A'
    addi $t5, $t5, 10 #value = 10 + (c- 'A')
    j add_sum
invalid_char:
    j next_char   #Skip invalid character 
add_sum:
    #Check if in first half 
    blt $t0, 5, add_g
    add $s1, $s1, $t5  #Add to H 
    j next_char
add_g:
    add $s0, $s0, $t5  #Add to G
next_char:
    addi $t0, $t0, 1  #i + 1
    j process_loop
end_loop:
    #Check if total sum is zero
    add $t6, $s0, $s1
    beqz $t6, print_na

    #Calculate and print G - H 
    sub $a0,$s0,$s1
    li $v0, 1
    syscall
    j exit

print_na:
    #print N/A 
    la $a0, n_a
    li $v0, 4
    syscall

exit:
    #Exit program
    li $v0, 10
    syscall