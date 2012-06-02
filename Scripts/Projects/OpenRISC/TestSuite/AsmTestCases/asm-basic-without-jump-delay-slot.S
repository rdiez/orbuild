/* Tests some basic CPU instructions.

   Copyright (C) 1999-2006 OpenCores
     Contributors various OpenCores participants
   Copyright (C) 2010 Embecosm Limited
     Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
   Copyright (C) 2012 R. Diez


   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3 of the License, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
   more details.

   You should have received a copy of the GNU General Public License along
   with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "AsmTestEnvironment.inc"

        
        STANDARD_TEST_ENVIRONMENT

        .section .text
start_tests:
        PUSH LINK_REGISTER_R9

        // ------ Test the jump instructions -----
        
        l.addi  r8,r0,0

        l.j _T1
        l.addi  r8,r8,1

_T2:    l.jr    r9
        l.addi  r8,r8,1

_T1:    l.jal   _T2
        l.addi  r8,r8,1

        l.sfeqi r0,0
        l.bf    _T3
        l.addi  r8,r8,1

_T3:    l.sfeqi r0,1
        l.bf    _T4
        l.addi  r8,r8,1
    
        l.addi  r8,r8,1

_T4:    l.sfeqi r0,0
        l.bnf    _T5
        l.addi  r8,r8,1

        l.addi  r8,r8,1

_T5:    l.sfeqi r0,1
        l.bnf    _T6
        l.addi  r8,r8,1
 
        l.addi  r8,r8,1

_T6:    l.movhi r3,hi(_T7)
        l.ori  r3,r3,lo(_T7)
        l.mtspr r0,r3,32
        l.mfspr r5,r0,17
        l.mtspr r0,r5,64
        l.rfe
        l.addi  r8,r8,1     // l.rfe should not have a delay slot

        l.addi  r8,r8,1

_T7:    REPORT_REG_TO_CONSOLE r8

        
        POP LINK_REGISTER_R9
        RETURN_TO_LINK_REGISTER_R9
