.data
    bitmap_name: .asciiz "output.bmp"
    enter_file: .asciiz "/home/mariusz/workspace/mips_project/input.bin"
    .align 0
bmpheader:
    .ascii "BM" # 00>BITMAPFILEHEADER.bfType   
    .word 90054     # 02>BITMAPFILEHEADER.bfSize
    .half 0     # 06>BITMAPFILEHEADER.bfReserved1
    .half 0     # 08>BITMAPFILEHEADER.bfReserved2
    .word 54    # 10>BITMAPFILEHEADER.bfOffBits

    .word 40    # 14>BITMAPINFOHEADER.biSize
    .word 600   # 18>BITMAPINFOHEADER.biWidth
    .word 50	# 22>BITMAPINFOHEADER.biHeight
    .half 1     # 26>BITMAPINFOHEADER.biPlanes
    .half 24    # 28>BITMAPINFOHEADER.biBitCount
    .word 0     # 30>BITMAPINFOHEADER.biCompression
    .word 0  # 34>BITMAPINFOHEADER.biSizeImage;
    .word 1800  # 38>BITMAPINFOHEADER.biXPelsPerMeter
    .word 150   # 42>BITMAPINFOHEADER.biYPelsPerMeter
    .word 0     # 46>BITMAPINFOHEADER.biClrUsed
    .word 0     # 50>BITMAPINFOHEADER.biClrImportant
    .align 2
pixelArray:
    .space 90000
    
.text
	

main:
	
	jal   make_bitmap_white
	
	li    $v0, 13
	la    $a0, enter_file	#open input file
	move  $a1, $zero
	move  $a2, $zero
	syscall
	
	move  $s0, $v0   #s0 store file_descriptor of enter file
	
	li    $v0, 9	#initialize buff in heap
	li    $a0, 2
	syscall
	
	move  $s1, $v0   # $s1 point to input data
	
	li    $s2, 1    # $s2 store direction turtle
	li    $s3, 1    # $s3 store ud
	li    $s4, 0    # $s4 hold color of turtle
	li    $s5, 0    # $s5 hold number of bits to color up
	li    $s6, 0    # $s6 hold x position
	li    $s7, 0	# $s7 hold y position
	
	jal   commit_commands
	
	li    $v0, 16	#close input file
	move  $a0, $s0
        syscall
	li    $v0, 13
        la    $a0, bitmap_name	#file name 
        li    $a1, 1		#flags: 1-write file
        li    $a2, 0		#mode: ignored
        syscall
	move  $s0, $v0           # save the file descriptor
	li    $v0, 15
	move  $a0, $s0
	la    $a1, bmpheader
	li    $a2, 90062	#size of file
	syscall
	
	li    $v0, 16	#close bmp file
	move  $a0, $s0	# $a0 hold file descriptor
        syscall
        

	li    $v0, 10  # end of program
	syscall

make_bitmap_white:
	sub   $sp, $sp, 4		#push $ra to the stack
	sw    $ra, 4($sp)
	li    $t1, 0xFFFFFFFF
	la    $t0, pixelArray	# Array pixel size divide by length of word: 90000/4 = 22500
	addiu $t2, $t0, 90000
fill_white:
	sw    $t1, ($t0)
	addiu $t0, $t0, 4
	bne   $t0, $t2, fill_white
	
	lw    $ra, 4($sp)		#restore (pop) $ra
	add   $sp, $sp, 4
	jr    $ra


commit_commands:
	addiu $sp, $sp, -4
	sw    $ra, ($sp)
loop:
	li    $v0, 14
	move  $a0, $s0
	move  $a1, $s1
	li    $a2, 2
	syscall
	blez  $v0, end_loop
	lbu   $t1,  ($s1)	#get upper byte of commend
	lbu   $t0, 1($s1)	#get lower byte of commend
	sll   $t1, $t1, 8	
	or    $t0, $t0, $t1	#connect two bytes
	andi  $t2, $t0, 3	#$t2 store information about type of commend
	srl   $t0, $t0, 2
	bne   $t2, 0, check_is_move
	jal   set_pen_state
	j     next_iter
check_is_move:
	bne   $t2, 1, check_is_set_direction
	jal   Move
	j     next_iter
check_is_set_direction:
	bne   $t2, 2, check_is_set_position
	jal   set_direction
	j     next_iter
check_is_set_position:
	bne   $t2, 3, next_iter
	jal   set_position
next_iter:
	j     loop
end_loop:
	lw    $ra, ($sp)
	addiu $sp, $sp, 4
	jr    $ra
	
set_pen_state:
	srl   $t0, $t0, 1	
	andi  $s3, $t0, 1	#check 4th bit - 1 means pen up, 0 down
	srl   $t0, $t0, 10
	bne   $t0, 0, check_if_red
	li    $s4, 0x000000	#set color black (0,0,0)
	jr    $ra
check_if_red:
	bne   $t0, 1, check_if_green
	li    $s4, 0xFF0000	#set color red (255,0,0)
	jr    $ra
check_if_green:
	bne   $t0, 2, check_if_blue
	li    $s4, 0x008000   #set color green (0,128,0)
	jr    $ra
check_if_blue:
	bne   $t0, 3, check_if_yellow
	li    $s4, 0x0000FF	#set color blue (0,0,255)
	jr    $ra
check_if_yellow:
	bne   $t0, 4, check_if_cyan
	li    $s4, 0xFFFF00	#set color yellow (255,255,0)
	jr    $ra
check_if_cyan:
	bne   $t0, 5, check_if_purple
	li    $s4, 0x00FFFF	#set color cyan (0,255,255)
	jr    $ra
check_if_purple:
	bne   $t0, 6, else_white
	li    $s4, 0x800080	#set color purple (128,0,128)
	jr    $ra
else_white:
	li    $s4, 0xFFFFFF	#set color white (255,255,255)
	jr    $ra

Move:
	sub   $sp, $sp, 4	#push $ra to the stack
	sw    $ra, 4($sp)
	andi  $s5, $t0, 0x3FF	#clear upper 4 bits and get length of move
	la    $t0, pixelArray	# load begin adress of pixelArray
	mul   $t1, $s7, 1800	# every line has 1800 bytes length
	mul   $t2, $s6, 3	# pixel has 3 bytes
	addu  $t1, $t1, $t2	# offset_y + offset_x = offset_pixel
	addu  $t0, $t0, $t1	# begin pixelArray + offset_pixel = addres_of_pixel
	beq   $s2, 0, move_right
	beq   $s2, 1, move_up
	beq   $s2, 2, move_left
	beq   $s2, 3, move_down
	
end_Move:
	lw    $ra, 4($sp)		#restore (pop) $ra
	add   $sp, $sp, 4
	jr    $ra

move_right:
	addu  $s6, $s6, $s5
	bleu  $s6, 599, move_right_set	
	subiu $t3, $s6, 600
	sub   $s5, $s5, $t3
	li    $s6, 599
move_right_set:
	beq   $s3, 0, end_Move
	li    $t3, 3  # offset of next pixel
	j     loop_move
move_up:
	addu  $s7, $s7, $s5
	bleu  $s7, 49,  move_up_set
	subiu $t3, $s7, 50
	sub   $s5, $s5, $t3
	li    $s7, 49
move_up_set:
	beq   $s3, 0, end_Move
	li    $t3, 1800 # offset of next pixel
	j     loop_move
move_left:
	subu  $s6, $s6, $s5
	bgtz   $s6, move_left_set
	add   $s5, $s5, $s6
	li    $s6, 0
move_left_set:
	beq   $s3, 0, end_Move
	li    $t3, -3	# offset of next pixel
	j     loop_move
move_down:
	sub   $s7, $s7, $s5
	bgtz  $s7, move_down_set
	add   $s5, $s5, $s7
	li    $s7, 0
move_down_set:
	beq   $s3, 0, end_Move
	li    $t3, -1800  # offset of next pixel
	j     loop_move

loop_move:
	sb    $s4, 0($t0)	#store first byte of color
	srl   $t2, $s4, 8	#get second byte of color
	sb    $t2, 1($t0)	#store second byte of color
	srl   $t2, $s4, 16	#get third byte of color
	sb    $t2, 2($t0)	#store third byte of color
	add   $t0, $t0, $t3	#t3 store offset next pixel
	addiu $s5, $s5, -1
	bge   $s5, 1, loop_move
	j     end_Move
set_direction:
	andi  $s2, $t0, 0x3	#get fisrt two bits 
	jr    $ra
set_position:
	srl   $s6, $t0, 4	#get x cord
	li    $v0, 14
	move  $a0, $s0
	move  $a1, $s1
	li    $a2, 2
	syscall
	lbu   $t0, ($s1)	
	srl   $s7, $t0, 2	#get y cord
	jr    $ra



