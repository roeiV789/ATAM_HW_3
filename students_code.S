.global	compute_char_repeats, parse_lines

.section .text
compute_char_repeats:
	#manual:
	#rdi = buffer
	#rsi = line_length
	#rdx = special_char

	xorq %rax, %rax
		.char_check_loop:
			cmpq $0, %rsi
			je .end_of_func
			cmpb (%rdi), %dl
			jne .end_loop
			addq $1, %rax

			.end_loop:
				subq $1, %rsi
				incq %rdi
				jmp .char_check_loop
			
	.end_of_func:
		ret

#compute_char_repeats:
#    .setup_ccr:
#		xorq %rax, %rax
#        leaq (%rdi ,%rsi), %rcx
#		cmpq $0 , %rsi
#		je .end_loop_ccr
#
#    .loop_ccr:
#    .check_length_ccr:
#        cmpq %rcx,%rdi
#		jl .check_character_ccr
#		jmp .end_loop_ccr
#		
#	.check_character_ccr:
#		movb (%rdi), %r8b
#		incq %rdi
#		cmpb %r8b, %dl
#		jne .loop_ccr
#		incq %rax
#		jmp .loop_ccr
#		
#	
#	.end_loop_ccr:
#		ret

parse_lines:
    # Function parameters:
    # %rdi = path (file path string)
    # %rsi = line_max_len - pointer to store the max line length
    # %rdx = line_max_repeat (pointer to store max repeat count)
	
	#manual:
	#rsi,rdx,rax,rdi - used as function parameters for calls
	#rbx - counts the length of the current line
	#rcx -  
	#r8 - holds a pointer to the start of the buffer
	#r9 - will count the number of lines
	#r10 - 
	#r11 - holds the file descriptor
	#r12 - holds a pointer to the current char
	#r13 - holds pointer to line_max_len
	#r14 - holds pointer to line_max_repeat
	#r15 - holds the special char
	
	.setup_pl:
		#saving registers that are used in the program by caller convention
		pushq %rbp 
		movq %rsp, %rbp 
		pushq %rbx
		pushq %r12
		pushq %r13
		pushq %r14
		pushq %r15
		
		movq %rdi, %r12 
		movq %rsi, %r13 
		movq %rdx, %r14 
		
		xorq %r9, %r9 
		xorq %rbx, %rbx 
		
		call get_the_special_char
		movb %al, %r15b
		
	.open_file:
		#now we will open the file so we can read from it
		movq $0, %rsi
		movq $2, %rax
		movq %r12, %rdi 
		syscall
		#we don't check if file opened successfully because it is given that this should work
		movq %rax,%r11 
		
	#allocate space for reading on the stack - 128+16
	subq $144, %rsp
	movq %rsp, %r8
	movq %r8, %r12 #initiate the current letter
	
	.process_file_lines:	
		jmp .read_from_file		
				
		.end_of_line:
		
			.max_line_check:
				cmpl (%r13), %ebx
				jle .calc_appearances
				movl %ebx, (%r13)
			
			.calc_appearances:
				movq %r8, %rdi #move buffer
				movb %r15b, %dl #move special char
				movq %rbx, %rsi #move line length
				call compute_char_repeats
			
			.max_special_check:
				cmpl (%r14), %eax
				jle .update_counters_end_of_line
				movl %eax, (%r14) 
	
			.update_counters_end_of_line:
				#reached a new line, so we need to reset counter of line length, increment lines in file counter, and reset the buffer
				xorq %rbx, %rbx
				addq $1, %r9
				movq %r8, %r12
				cmpq $0, %rcx #rcx holds the number of bytes that were read in last syscall - check if the current check is the last one
				je .end_file
		.continue_loop:
			jmp .process_file_lines
		


	.read_from_file:
			movq %r11,%rdi #we move the file descriptor
			movq $0, %rax #read-only
			movq $1 , %rdx #number of bytes to read
			movq %r12, %rsi # buffer
			syscall #after this executes, we have a pointer to a letter stored in %r12
			movq %rax, %rcx
			cmpq $0, %rax
			je .end_of_line
			movq %rax, %rcx
			cmpb $10, (%r12)
			je .end_of_line
			addq $1, %r12
			addq $1, %rbx #increment letter counter in current string
			jmp .continue_loop
		
	
	.end_file:
		movq %r9, %rax
		addq $144, %rsp
		popq %r15
		popq %r14
		popq %r13
		popq %r12
		leave
		ret
			
