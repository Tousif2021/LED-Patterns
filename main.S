.section .text
/////////////////////////////////////////////////////////////////////////////////////
// GPIO General Purpose I/0 Subroutine package                         0.91 AC
/////////////////////////////////////////////////////////////////////////////////////
.equ GPIOA,  0x40010800     // GPIOB Base address.
.equ GPIOB,  0x40010C00     // GPIOB Base address.
.equ CTR0,   0x00           // Port control register 0 offset
.equ ISTAT,  0x08           // Port input status register
.equ OCTL,   0x0C           // Port output control register
.equ BOP,    0x10           // Port bit operate register offset
.equ BC,     0x14           // Port bit clear register offset
.equ GPIO_AM, 0x0           // Mode: Input, Analog Mode
.equ GPIO_50, 0x3           // Mode: Output, max speed 50MHz
.equ GPIO_FI, 0x4           // Conf: (Input) Floating input
.equ GPIO_UD, 0x8           // Conf: (Input) Pull-up/-down
.equ GPIO_PP, 0x0           // Conf: (Output) Push-pull
.equ GPIO_OD, 0x4           // Conf: (Output) Open-drain

// GPIOI Initialize ////////////////////////////////////////////////// 1.0 / AC ////
// a0 Targeted GPIO-module
// a1 Configuration bits (<<2)
// a2 Mode bits
// a3 Targeted pin
gpioi:  mv t0, a0           // t0 points to GPIOX...
        mv t4, a3           //    t4 marks selected pin...
        li t1,0x8           //    Use port control register 0 or 1,
        blt t4,t1, 1f       //    thus is pin > 7?
        addi t0, t0, 4      //       Yes, adjust base address,
        addi t4,t4,-8       //            and adjust selected pin.

1:      slli t4,t4,2        //    Multiply pin nb by 4 to get steps to shift!
        li t1, 0xF          //    Create inverted configuration mask...
        sll t1, t1, t4      //    ...and move it into right position.
        not t1, t1          //    ...invert it back, then...
        mv t2, a1           //    Create configuration bits...
        or t2, t2, a2       //    
        sll t2, t2, t4      //    ...and move it into right position.

        lw t3,CTR0(t0)      //    retreive port control register 0(/1)...
        and t3,t3,t1        //    ...clear out selected pin's config/mode bits...
        or t3, t3, t2       //    ...configure new config/mode bits...
        sw t3,CTR0(t0)      //    ...and write it back.
        ret                 //  then go home!

// GPIOBO Bit Operations ///////////////////////////////////////////// 1.0 / AC ///
// a0 Targeted GPIO-module
// a1 Targeted pattern
// a2 Targeted pin(s)
gpiobo: and a1, a1, a2      // (Clear all patterns bits that are not target bits)
        xor a2, a2, a1      // Find zeros in targeted bits...
        slli a2, a2, 16     // ...position clear requests...
        or a1, a1, a2       // ...add set requests...
        sw a1, BOP(a0)      // ...then execute...
        ret                 // ...and return to caller!

// GPIBC Bit Clear /////////////////////////////////////////////////// 1.0 / AC ///
// a0 Targeted GPIO-module
// a1 Targeted pin(s)
gpiobc: sw a1, BC(a0)       // Execute request...
        ret                 // ...and return to caller!

// GPIOC Output Control ////////////////////////////////////////////// 1.0 / AC ///
// a0 Targeted GPIO-module
// a1 value
gpiooc: sw a1, OCTL(a0)      // Execute request...
        ret                 // ...and return to caller!

// GPIOIS Input Status //////////////////////////////////////////////// 1.0 / AC ///
// a0 Targeted GPIO-module
// a1 read value
gpiois: lw a1, ISTAT(a0)    // Execute request...
        ret                 // ...and return to caller!

// GPIO General Purpose I/0 Subroutine package ////////////////////////// END ///////

/////////////////////////////////////////////////////////////////////////////////////
// RCU Reset and Clock Unit Subroutine package                         0.91 AC
/////////////////////////////////////////////////////////////////////////////////////
.equ RCU,    0x40021000
.equ APB1EN, 0x1C
.equ T5EN,   0x10
.equ APB2EN, 0x18
.equ PAEN,   0x4
.equ PBEN,   0x8
// RCU1EN Enabel APB1 bus devices //////////////////////////////////// 1.0 / AC ///
rcu1en: li t0,RCU           // t0 points to RCU...
        lw t1,APB1EN(t0)    // ...retrieve current configuration...
        or t1,t1,a0         // ...and update the configuration...
        sw t1,APB1EN(t0)    // ...then save back the updated config...
        ret                 // and go home!

// RCU2EN Enabel APB2 bus devices //////////////////////////////////// 1.0 / AC ///
rcu2en: li t0,RCU           // t0 points to RCU...
        lw t1,APB2EN(t0)    // ...retrieve current configuration...
        or t1,t1,a0         // ...and update the configuration...
        sw t1,APB2EN(t0)    // ...then save back the updated config...
        ret                 // and go home!
        
// RCU Reset and Clock Unit Subroutine package ////////////////////////// END /////// 


/////////////////////////////////////////////////////////////////////////////////////
//                                LAB 1 Nivå 2                                     //
/////////////////////////////////////////////////////////////////////////////////////
.section .text
.global main

.equ DELAY_COUNT, 1000000    // Adjust based on CPU clock to get approx 0.25 second

// Function to implement delay
delay_250ms:
    li t0, DELAY_COUNT
1:  addi t0, t0, -1
    bnez t0, 1b
    ret

main:
    li a0, PBEN+PAEN         // Enable GPIOB and GPIOA
    call rcu2en              // Setup clock

    li a0, GPIOB             // Set GPIOB pins 0, 1, 2 as output
    li a1, GPIO_PP           // Push-Pull output configuration
    li a2, GPIO_50           // Max speed 50MHz
    li a3, 0                 // Start from pin 0
    li a4, 3                 // Up to pin 2
1:  call gpioi               // Initialize pin
    addi a3, a3, 1
    blt a3, a4, 1b           // Loop for all three pins

    li a0, GPIOA             // Set GPIOA pins 5 to 8 as input
    li a1, GPIO_AM           // Analog mode (floating input here if needed)
    li a2, GPIO_FI           // High-Z floating input
    li a3, 5                 // Start from pin 5
    li a4, 9                 // Up to pin 8
1:  call gpioi               // Initialize pin
    addi a3, a3, 1
    blt a3, a4, 1b           // Loop for all four pins

// Main loop
main_loop:
    li a0, GPIOA             // Prepare to read GPIOA
    call gpiois              // Read the input state
    andi a1, a1, 0x01E0      // Mask for pins A5 to A8
    li t2, 0x0100            // Mask to check if A8 is high (inversion switch)
    and t3, a1, t2           // Check if A8 is set
    beqz t3, normal_sequences // If A8 is not set, go to normal sequences
    j inverted_sequences       // If A8 is set, go to inverted sequences

normal_sequences:
    # Normal sequences without inversion
    li t1, 0x0000
    beq a1, t1, seq0_normal_sequence
    li t1, 0x0020
    beq a1, t1, seq1_blinking_sequence
    li t1, 0x0040
    beq a1, t1, seq2_alternating_blink
    li t1, 0x0080
    beq a1, t1, seq3_running_lights
    li t1, 0x0060
    beq a1, t1, seq4_single_blink_then_all_on
    li t1, 0x00A0
    beq a1, t1, seq5_sequential_off
    li t1, 0x00C0
    beq a1, t1, seq6_all_on_off_blink
    li t1, 0x00E0
    beq a1, t1, seq7_zigzag
    # li t1, 0x01E0
    # beq a1, t1, seq8_random_blink
    j main_loop

inverted_sequences:
    # Inverted sequences
    li t1, 0x0100
    beq a1, t1, seq0_inverted_sequence
    li t1, 0x0120
    beq a1, t1, seq1_inverted_blinking_sequence
    li t1, 0x0140
    beq a1, t1, seq2_inverted_alternating_blink
    li t1, 0x0180
    beq a1, t1, seq3_inverted_running_lights
    li t1, 0x0160
    beq a1, t1, seq4_inverted_single_blink_then_all_on
    li t1, 0x01A0
    beq a1, t1, seq5_inverted_sequential_off
    li t1, 0x01C0
    beq a1, t1, seq6_inverted_all_on_off_blink
    li t1, 0x01E0
    beq a1, t1, seq7_inverted_zigzag
    # li t1, 0x0200
    # beq a1, t1, seq8_random_blink_inverted
    j main_loop

# Sequence definitions
seq0_normal_sequence:
    li a0, GPIOB
    li a1, 0x00              # All LEDs off
    call gpiooc
    call delay_250ms
    li a1, 0x04              # PB2
    call gpiooc
    call delay_250ms
    li a1, 0x02              # PB1
    call gpiooc
    call delay_250ms
    li a1, 0x01              # PB0
    call gpiooc
    call delay_250ms
    j main_loop

seq0_inverted_sequence:
    li a0, GPIOB
    li a1, 0x00              # All LEDs on|off
    call gpiooc
    call delay_250ms
    li a1, 0x03              # All except PB2
    call gpiooc
    call delay_250ms
    li a1, 0x05              # All except PB1
    call gpiooc
    call delay_250ms
    li a1, 0x06              # All except PB0
    call gpiooc
    call delay_250ms
    j main_loop
seq1_blinking_sequence:
    # Normal sequence when A5 is high and A8 is not
    li a0, GPIOB
    li a1, 0x00             # All LEDs off
    call gpiooc
    call delay_250ms
    li a1, 0x01              # PB0
    call gpiooc
    call delay_250ms
    li a1, 0x02              # PB1
    call gpiooc
    call delay_250ms
    li a1, 0x04              # PB2
    call gpiooc
    call delay_250ms
    j main_loop

seq1_inverted_blinking_sequence:
    # Inverted sequence when A5 and A8 are both high
    li a0, GPIOB
    li a1, 0x07              # All LEDs on
    call gpiooc
    call delay_250ms
    li a1, 0x06              # All except PB0
    call gpiooc
    call delay_250ms
    li a1, 0x05              # All except PB1
    call gpiooc
    call delay_250ms
    li a1, 0x03              # All except PB2
    call gpiooc
    call delay_250ms
    j main_loop

seq2_alternating_blink:
    # Normal sequence when A6 is high and A8 is not
    li a0, GPIOB
    li a1, 0x00             # All LEDs off
    call gpiooc
    call delay_250ms
    li a1, 0x05              # PB0 and PB2 on
    call gpiooc
    call delay_250ms
    li a1, 0x02              # PB1 on
    call gpiooc
    call delay_250ms
    j main_loop

seq2_inverted_alternating_blink:
    # Inverted sequence when A6 and A8 are both high
    li a0, GPIOB
    li a1, 0x02              # only PB1 on
    call gpiooc
    call delay_250ms
    li a1, 0x00              # All LEDs off
    call gpiooc
    call delay_250ms
    li a1, 0x05             # PB0 and PB2 on
    call gpiooc
    call delay_250ms
    j main_loop

seq3_running_lights:
    # Normal sequence when A7 is high and A8 is not
    li a0, GPIOB
    li a1, 0x00             # All LEDs off
    call gpiooc
    call delay_250ms
    li a1, 0x01              # PB0 on
    call gpiooc
    call delay_250ms
    li a1, 0x02              # PB1 on
    call gpiooc
    call delay_250ms
    li a1, 0x04              # PB2 on
    call gpiooc
    call delay_250ms
    j main_loop

seq3_inverted_running_lights:
    # Inverted sequence when A7 and A8 are both high
    li a0, GPIOB
    li a1, 0x07             # All LEDs on
    call gpiooc
    call delay_250ms
    li a1, 0x06              # All except PB0
    call gpiooc
    call delay_250ms
    li a1, 0x05              # All except PB1
    call gpiooc
    call delay_250ms
    li a1, 0x03              # All except PB2
    call gpiooc
    call delay_250ms
    j main_loop

seq4_single_blink_then_all_on:
    # Normal sequence when A5 and A6 are high and A8 is not
    li a0, GPIOB
    li a1, 0x00             # All LEDs off
    call gpiooc
    call delay_250ms

    li a1, 0x01              # PB0 on
    call gpiooc
    call delay_250ms
    
    li a1, 0x07              # All LEDs on
    call gpiooc
    call delay_250ms


    li a1, 0x02              # PB1 on
    call gpiooc
    call delay_250ms

    li a1, 0x07              # All LEDs on
    call gpiooc
    call delay_250ms

    li a1, 0x04              # PB2 on
    call gpiooc
    call delay_250ms

    li a1, 0x07              # All LEDs on
    call gpiooc
    call delay_250ms
    
    j main_loop

seq4_inverted_single_blink_then_all_on:

    # Inverted sequence when A5, A6 and A8 are all high
    li a0, GPIOB
    li a1, 0x07             # All LEDs on
    call gpiooc
    call delay_250ms

    li a1, 0x06              # All except PB0
    call gpiooc
    call delay_250ms

    li a0, GPIOB
    li a1, 0x00             # All LEDs off
    call gpiooc
    call delay_250ms

    li a1, 0x05              # All except PB1
    call gpiooc
    call delay_250ms

    li a0, GPIOB
    li a1, 0x00             # All LEDs off
    call gpiooc
    call delay_250ms

    li a1, 0x03              # All except PB2
    call gpiooc
    call delay_250ms

    li a0, GPIOB
    li a1, 0x00             # All LEDs off
    call gpiooc
    call delay_250ms
    j main_loop

seq5_sequential_off:
    # Normal sequence when A5 and A7 are high and A8 is not
    li a0, GPIOB
    li a1, 0x07             # All LEDs on
    call gpiooc
    call delay_250ms
    li a1, 0x06              # All except PB0
    call gpiooc
    call delay_250ms
    li a1, 0x05              # All except PB1
    call gpiooc
    call delay_250ms
    li a1, 0x03              # All except PB2
    call gpiooc
    call delay_250ms
    li a1, 0x00              # All LEDs off
    call gpiooc
    call delay_250ms
    j main_loop

seq5_inverted_sequential_off:
    # Inverted sequence when A5, A7 and A8 are all high
    li a0, GPIOB
    li a1, 0x00             # All LEDs off
    call gpiooc
    call delay_250ms
    li a1, 0x01              # PB0 on
    call gpiooc
    call delay_250ms
    li a1, 0x02              # PB1 on
    call gpiooc
    call delay_250ms
    li a1, 0x04              # PB2 on
    call gpiooc
    call delay_250ms
    li a1, 0x07              # All LEDs on
    call gpiooc
    call delay_250ms
    j main_loop
seq6_all_on_off_blink:
    # Normal sequence when A6 and A7 are high and A8 is not
    li a0, GPIOB
    li a1, 0x07             # All LEDs on
    call gpiooc
    call delay_250ms
    li a1, 0x00              # All LEDs off
    call gpiooc
    call delay_250ms
    li a1, 0x07             # All LEDs on
    call gpiooc
    call delay_250ms
    li a1, 0x00              # All LEDs off
    call gpiooc
    call delay_250ms
    j main_loop

seq6_inverted_all_on_off_blink:
    # Inverted sequence when A6, A7 and A8 are all high
    li a0, GPIOB
    li a1, 0x00             # All LEDs off
    call gpiooc
    call delay_250ms
    li a1, 0x07             # All LEDs on
    call gpiooc
    call delay_250ms
    li a1, 0x00             # All LEDs off
    call gpiooc
    call delay_250ms
    li a1, 0x07             # All LEDs on
    call gpiooc
    call delay_250ms
    j main_loop
seq7_zigzag:
    # Normal sequence when A5, A6 and A7 are high and A8 is not
    li a0, GPIOB
    li a1, 0x00             # All LEDs off
    call gpiooc
    call delay_250ms
    li a1, 0x01              # PB0 on
    call gpiooc
    call delay_250ms
    li a1, 0x06              # PB1 and PB2 on
    call gpiooc
    call delay_250ms
    li a1, 0x05              # PB0 and PB1 on
    call gpiooc
    call delay_250ms
    li a1, 0x03              # PB2 on
    call gpiooc
    call delay_250ms
    j main_loop
seq7_inverted_zigzag:
    # Inverted sequence when A5, A6, A7 and A8 are all high
    li a0, GPIOB
    li a1, 0x07             # All LEDs on
    call gpiooc
    call delay_250ms
    li a1, 0x06              # All except PB0
    call gpiooc
    call delay_250ms
    li a1, 0x05              # All except PB1
    call gpiooc
    call delay_250ms
    li a1, 0x03              # All except PB2
    call gpiooc
    call delay_250ms
    li a1, 0x01              # PB0 on
    call gpiooc
    call delay_250ms
    j main_loop

.end
