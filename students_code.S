.global	compute_char_repeats, parse_lines

.section .text
compute_char_repeats:
    setup_ccr:
		xorq %rax, %rax
        leaq (%rdi ,%rsi), %rcx
		cmpq $0 , %rsi
		je end_loop_ccr

    loop_ccr:
    check_length_ccr:
        cmpq %rcx,%rdi
		jl check_character_ccr
		jmp end_loop_ccr
		
	check_character_ccr:
		movb (%rdi), %r8b
		inc %rdi
		cmpb %r8b, %dl
		jne loop_ccr
		inc %rax
		jmp loop_ccr
		
	
	end_loop_ccr:
		ret


parse_lines:
    # Function parameters:
    # %rdi = path (file path string)
    # %rsi = line_max_len - pointer to store the max line length
    # %rdx = line_max_repeat (pointer to store max repeat count)
	
	#manual:
	#rsi,rdx,rax,rdi - used as function parameters for calls
	#rbx - counts the length of the current line
	#rcx - holds the line_max_len
	#r8 - holds a pointer to the start of the buffer
	#r9 - will count the number of lines
	#r10 - holds line_max_repeat
	#r11 - 
	#r12 - holds a pointer to the current char
	#r13 - 
	#r14 - holds the file descriptor
	#r15 - holds the special char
	
	setup_pl:
		#saving registers that are used in the program by caller convention
		pushq %rbp 
		movq %rsp, %rbp 
		pushq %rbx
		pushq %r12
		pushq %r13
		pushq %r14
		pushq %r15
		pushq %rsi
		pushq %rdx
		
		movq %rdi, %r12 
		
		xorq %r9, %r9 
		xorq %rbx, %rbx 
		xorq %rcx, %rcx
		xorq %r10, %r10
		
		pushq %rdi
		pushq %rsi
		pushq %rdx
		pushq %rcx
		pushq %r8
		pushq %r9
		pushq %r10
		pushq %r11
		call get_the_special_char
		popq %r11
		popq %r10
		popq %r9
		popq %r8
		popq %rcx
		popq %rdx
		popq %rsi
		popq %rdi
		
		movb %al, %r15b
		
	open_file:
		#now we will open the file so we can read from it
		movq $0, %rsi
		movq $2, %rax
		movq %r12, %rdi
		pushq %rcx
		pushq %r8
		pushq %r9
		pushq %r10
		pushq %r11
		syscall
		popq %r11
		popq %r10
		popq %r9
		popq %r8
		popq %rcx
		#we don't check if file opened successfully because it is given that this should work
		movq %rax,%r14 
		
	#allocate space for reading on the stack - 128+16
	subq $144, %rsp
	movq %rsp, %r8
	movq %r8, %r12 #initiate the current letter
	
	process_file_lines:	
		jmp read_from_file		
				
		end_of_line:
			.db1:
			max_line_check:
				cmpq %rcx, %rbx
				jle calc_appearances
				movq %rbx, %rcx
			
			calc_appearances:
				movq %r8, %rdi #move buffer
				movb %r15b, %dl #move special char
				movq %rbx, %rsi #move line length
				pushq %rcx
				pushq %r8
				pushq %r9
				pushq %r10
				pushq %r11
				call compute_char_repeats
				popq %r11
				popq %r10
				popq %r9
				popq %r8		
				popq %rcx
			max_special_check:
				cmpq %r10, %rax
				jle update_counters_end_of_line
				movq %rax, %r10 
	
			update_counters_end_of_line:
				#reached a new line, so we need to reset counter of line length, increment lines in file counter, and reset the buffer
				xorq %rbx, %rbx
				addq $1, %r9
				movq %r8, %r12
				cmpq $0, %r13 #rcx holds the number of bytes that were read in last syscall - check if the current check is the last one
				je end_file
		continue_loop:
			jmp process_file_lines
		


	read_from_file:
			movq %r14,%rdi #we move the file descriptor
			movq $0, %rax #read-only
			movq $1 , %rdx #number of bytes to read
			movq %r12, %rsi # buffer
			pushq %rcx
			pushq %r8
			pushq %r9
			pushq %r10
			pushq %r11	
			syscall #after this executes, we have a pointer to a letter stored in %r12
			popq %r11
			popq %r10
			popq %r9
			popq %r8		
			popq %rcx
			movq %rax, %r13
			cmpq $0, %rax
			je end_of_line
			
		.db4:
			cmpb $10, (%r12)
			je end_of_line
			inc %r12
			inc %rbx #increment letter counter in current string
			jmp continue_loop
		
	
	end_file:
		addq $144, %rsp
		popq %rdx
		popq %rsi
		movq %r9, %rax
		movq %rcx, (%rsi)
		movq %r10, (%rdx)
		popq %r15
		popq %r14
		popq %r13
		popq %r12
		popq %rbx
		leave
		ret
