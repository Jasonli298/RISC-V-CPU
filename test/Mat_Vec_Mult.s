N:
        .zero   4
R:
        .zero   4
MatVecMult(int (*) [4], int*, int*):
        addi    sp,sp,-48
        sw      s0,44(sp)
        addi    s0,sp,48
        sw      a0,-36(s0)
        sw      a1,-40(s0)
        sw      a2,-44(s0)
        sw      zero,-20(s0)
        j       .L2
.L5:
        lw      a5,-20(s0)
        slli    a5,a5,2
        lw      a4,-44(s0)
        add     a5,a4,a5
        sw      zero,0(a5)
        sw      zero,-24(s0)
        j       .L3
.L4:
        lw      a5,-20(s0)
        slli    a5,a5,2
        lw      a4,-44(s0)
        add     a5,a4,a5
        lw      a3,0(a5)
        lw      a5,-20(s0)
        slli    a5,a5,4
        lw      a4,-36(s0)
        add     a4,a4,a5
        lw      a5,-24(s0)
        slli    a5,a5,2
        add     a5,a4,a5
        lw      a4,0(a5)
        lw      a5,-24(s0)
        slli    a5,a5,2
        lw      a2,-40(s0)
        add     a5,a2,a5
        lw      a5,0(a5)
        mul     a4,a4,a5
        lw      a5,-20(s0)
        slli    a5,a5,2
        lw      a2,-44(s0)
        add     a5,a2,a5
        add     a4,a3,a4
        sw      a4,0(a5)
        lw      a5,-24(s0)
        addi    a5,a5,1
        sw      a5,-24(s0)
.L3:
        lui     a5,%hi(N)
        lw      a5,%lo(N)(a5)
        lw      a4,-24(s0)
        blt     a4,a5,.L4
        lw      a5,-20(s0)
        addi    a5,a5,1
        sw      a5,-20(s0)
.L2:
        lui     a5,%hi(R)
        lw      a5,%lo(R)(a5)
        lw      a4,-20(s0)
        blt     a4,a5,.L5
        nop
        nop
        lw      s0,44(sp)
        addi    sp,sp,48
        jr      ra
.LC2:
        .string "%i\n"
.LC0:
        .word   1
        .word   2
        .word   3
        .word   4
        .word   -2
        .word   6
        .word   7
        .word   0
        .word   4
        .word   3
        .word   2
        .word   1
.LC1:
        .word   1
        .word   0
        .word   2
        .word   1
main:
        addi    sp,sp,-112
        sw      ra,108(sp)
        sw      s0,104(sp)
        addi    s0,sp,112
        lui     a5,%hi(R)
        li      a4,3
        sw      a4,%lo(R)(a5)
        lui     a5,%hi(N)
        li      a4,4
        sw      a4,%lo(N)(a5)
        lui     a5,%hi(.LC0)
        addi    a5,a5,%lo(.LC0)
        lw      t5,0(a5)
        lw      t4,4(a5)
        lw      t3,8(a5)
        lw      t1,12(a5)
        lw      a7,16(a5)
        lw      a6,20(a5)
        lw      a0,24(a5)
        lw      a1,28(a5)
        lw      a2,32(a5)
        lw      a3,36(a5)
        lw      a4,40(a5)
        lw      a5,44(a5)
        sw      t5,-68(s0)
        sw      t4,-64(s0)
        sw      t3,-60(s0)
        sw      t1,-56(s0)
        sw      a7,-52(s0)
        sw      a6,-48(s0)
        sw      a0,-44(s0)
        sw      a1,-40(s0)
        sw      a2,-36(s0)
        sw      a3,-32(s0)
        sw      a4,-28(s0)
        sw      a5,-24(s0)
        lui     a5,%hi(.LC1)
        addi    a5,a5,%lo(.LC1)
        lw      a2,0(a5)
        lw      a3,4(a5)
        lw      a4,8(a5)
        lw      a5,12(a5)
        sw      a2,-84(s0)
        sw      a3,-80(s0)
        sw      a4,-76(s0)
        sw      a5,-72(s0)
        addi    a3,s0,-100
        addi    a4,s0,-84
        addi    a5,s0,-68
        mv      a2,a3
        mv      a1,a4
        mv      a0,a5
        call    MatVecMult(int (*) [4], int*, int*)
        sw      zero,-20(s0)
        j       .L7
.L8:
        lw      a5,-20(s0)
        slli    a5,a5,2
        addi    a5,a5,-16
        add     a5,a5,s0
        lw      a5,-84(a5)
        mv      a1,a5
        lui     a5,%hi(.LC2)
        addi    a0,a5,%lo(.LC2)
        call    printf
        lw      a5,-20(s0)
        addi    a5,a5,1
        sw      a5,-20(s0)
.L7:
        lui     a5,%hi(R)
        lw      a5,%lo(R)(a5)
        lw      a4,-20(s0)
        blt     a4,a5,.L8
        li      a5,0
        mv      a0,a5
        lw      ra,108(sp)
        lw      s0,104(sp)
        addi    sp,sp,112
        jr      ra