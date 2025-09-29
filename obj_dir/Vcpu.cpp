// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vcpu.h for the primary calling header

#include "Vcpu.h"
#include "Vcpu__Syms.h"

//==========

void Vcpu::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vcpu::eval\n"); );
    Vcpu__Syms* __restrict vlSymsp = this->__VlSymsp;  // Setup global symbol table
    Vcpu* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
#ifdef VL_DEBUG
    // Debug assertions
    _eval_debug_assertions();
#endif  // VL_DEBUG
    // Initialize
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) _eval_initial_loop(vlSymsp);
    // Evaluate till stable
    int __VclockLoop = 0;
    QData __Vchange = 1;
    do {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Clock loop\n"););
        _eval(vlSymsp);
        if (VL_UNLIKELY(++__VclockLoop > 100)) {
            // About to fail, so enable debug to see what's not settling.
            // Note you must run make with OPT=-DVL_DEBUG for debug prints.
            int __Vsaved_debug = Verilated::debug();
            Verilated::debug(1);
            __Vchange = _change_request(vlSymsp);
            Verilated::debug(__Vsaved_debug);
            VL_FATAL_MT("src/top.v", 3, "",
                "Verilated model didn't converge\n"
                "- See DIDNOTCONVERGE in the Verilator manual");
        } else {
            __Vchange = _change_request(vlSymsp);
        }
    } while (VL_UNLIKELY(__Vchange));
}

void Vcpu::_eval_initial_loop(Vcpu__Syms* __restrict vlSymsp) {
    vlSymsp->__Vm_didInit = true;
    _eval_initial(vlSymsp);
    // Evaluate till stable
    int __VclockLoop = 0;
    QData __Vchange = 1;
    do {
        _eval_settle(vlSymsp);
        _eval(vlSymsp);
        if (VL_UNLIKELY(++__VclockLoop > 100)) {
            // About to fail, so enable debug to see what's not settling.
            // Note you must run make with OPT=-DVL_DEBUG for debug prints.
            int __Vsaved_debug = Verilated::debug();
            Verilated::debug(1);
            __Vchange = _change_request(vlSymsp);
            Verilated::debug(__Vsaved_debug);
            VL_FATAL_MT("src/top.v", 3, "",
                "Verilated model didn't DC converge\n"
                "- See DIDNOTCONVERGE in the Verilator manual");
        } else {
            __Vchange = _change_request(vlSymsp);
        }
    } while (VL_UNLIKELY(__Vchange));
}

VL_INLINE_OPT void Vcpu::_combo__TOP__2(Vcpu__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu::_combo__TOP__2\n"); );
    Vcpu* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->dioptase__DOT__c0__DOT__theClock = (1U 
                                                & (~ (IData)(vlTOPp->dioptase__DOT__c0__DOT__theClock)));
}

VL_INLINE_OPT void Vcpu::_sequent__TOP__3(Vcpu__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu::_sequent__TOP__3\n"); );
    Vcpu* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Variables
    CData/*4:0*/ __Vdlyvlsb__dioptase__DOT__mem__DOT__ram__v0;
    CData/*7:0*/ __Vdlyvval__dioptase__DOT__mem__DOT__ram__v0;
    CData/*0:0*/ __Vdlyvset__dioptase__DOT__mem__DOT__ram__v0;
    CData/*4:0*/ __Vdlyvlsb__dioptase__DOT__mem__DOT__ram__v1;
    CData/*7:0*/ __Vdlyvval__dioptase__DOT__mem__DOT__ram__v1;
    CData/*0:0*/ __Vdlyvset__dioptase__DOT__mem__DOT__ram__v1;
    CData/*4:0*/ __Vdlyvlsb__dioptase__DOT__mem__DOT__ram__v2;
    CData/*7:0*/ __Vdlyvval__dioptase__DOT__mem__DOT__ram__v2;
    CData/*0:0*/ __Vdlyvset__dioptase__DOT__mem__DOT__ram__v2;
    CData/*4:0*/ __Vdlyvlsb__dioptase__DOT__mem__DOT__ram__v3;
    CData/*7:0*/ __Vdlyvval__dioptase__DOT__mem__DOT__ram__v3;
    CData/*0:0*/ __Vdlyvset__dioptase__DOT__mem__DOT__ram__v3;
    CData/*2:0*/ __Vdlyvdim0__dioptase__DOT__cpu__DOT__tlb__DOT__cache__v0;
    CData/*0:0*/ __Vdlyvset__dioptase__DOT__cpu__DOT__tlb__DOT__cache__v0;
    CData/*0:0*/ __Vdlyvset__dioptase__DOT__cpu__DOT__tlb__DOT__cache__v1;
    CData/*4:0*/ __Vdlyvdim0__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v0;
    CData/*0:0*/ __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v0;
    CData/*4:0*/ __Vdlyvdim0__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v1;
    CData/*0:0*/ __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v1;
    CData/*2:0*/ __Vdlyvdim0__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v0;
    CData/*0:0*/ __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v0;
    CData/*0:0*/ __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v1;
    CData/*0:0*/ __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v2;
    CData/*0:0*/ __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v3;
    CData/*0:0*/ __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v6;
    CData/*0:0*/ __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v7;
    CData/*0:0*/ __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v8;
    SData/*15:0*/ __Vdlyvdim0__dioptase__DOT__mem__DOT__ram__v0;
    SData/*15:0*/ __Vdlyvdim0__dioptase__DOT__mem__DOT__ram__v1;
    SData/*15:0*/ __Vdlyvdim0__dioptase__DOT__mem__DOT__ram__v2;
    SData/*15:0*/ __Vdlyvdim0__dioptase__DOT__mem__DOT__ram__v3;
    IData/*31:0*/ __Vdly__dioptase__DOT__cpu__DOT__clk_count;
    IData/*31:0*/ __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v0;
    IData/*31:0*/ __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v1;
    IData/*31:0*/ __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v0;
    IData/*31:0*/ __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v1;
    IData/*31:0*/ __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v2;
    IData/*31:0*/ __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v3;
    IData/*31:0*/ __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v4;
    IData/*31:0*/ __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v5;
    IData/*31:0*/ __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v6;
    IData/*31:0*/ __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v7;
    IData/*31:0*/ __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v8;
    QData/*38:0*/ __Vdlyvval__dioptase__DOT__cpu__DOT__tlb__DOT__cache__v0;
    // Body
    __Vdly__dioptase__DOT__cpu__DOT__clk_count = vlTOPp->dioptase__DOT__cpu__DOT__clk_count;
    __Vdlyvset__dioptase__DOT__mem__DOT__ram__v0 = 0U;
    __Vdlyvset__dioptase__DOT__mem__DOT__ram__v1 = 0U;
    __Vdlyvset__dioptase__DOT__mem__DOT__ram__v2 = 0U;
    __Vdlyvset__dioptase__DOT__mem__DOT__ram__v3 = 0U;
    __Vdlyvset__dioptase__DOT__cpu__DOT__tlb__DOT__cache__v0 = 0U;
    __Vdlyvset__dioptase__DOT__cpu__DOT__tlb__DOT__cache__v1 = 0U;
    __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v0 = 0U;
    __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v1 = 0U;
    __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v0 = 0U;
    __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v1 = 0U;
    __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v2 = 0U;
    __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v3 = 0U;
    __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v6 = 0U;
    __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v7 = 0U;
    __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v8 = 0U;
    if (VL_UNLIKELY(vlTOPp->dioptase__DOT__cpu__DOT__halt)) {
        VL_WRITEF("%08x\n",32,vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile
                  [3U]);
        VL_FINISH_MT("src/counter.v", 11, "");
    }
    if (VL_UNLIKELY((0x1f4U == vlTOPp->dioptase__DOT__cpu__DOT__ctr__DOT__count))) {
        VL_WRITEF("ran for 500 cycles\n");
        VL_FINISH_MT("src/counter.v", 15, "");
    }
    vlTOPp->dioptase__DOT__cpu__DOT__ctr__DOT__count 
        = ((IData)(1U) + vlTOPp->dioptase__DOT__cpu__DOT__ctr__DOT__count);
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_is_branch_out 
                    = vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__is_branch;
            }
        }
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out 
                    = (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                >> 0x16U));
            }
        }
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__writeback__DOT__mem_result_buf 
            = vlTOPp->dioptase__DOT__mem_read1_data;
    }
    if (vlTOPp->dioptase__DOT__clk_en) {
        if ((1U & (IData)(vlTOPp->dioptase__DOT__mem_write_en))) {
            __Vdlyvval__dioptase__DOT__mem__DOT__ram__v0 
                = (0xffU & vlTOPp->dioptase__DOT__cpu__DOT__store_data);
            __Vdlyvset__dioptase__DOT__mem__DOT__ram__v0 = 1U;
            __Vdlyvlsb__dioptase__DOT__mem__DOT__ram__v0 = 0U;
            __Vdlyvdim0__dioptase__DOT__mem__DOT__ram__v0 
                = (0xffffU & (vlTOPp->dioptase__DOT__cpu__DOT__tlb_out_1 
                              >> 2U));
        }
        if ((2U & (IData)(vlTOPp->dioptase__DOT__mem_write_en))) {
            __Vdlyvval__dioptase__DOT__mem__DOT__ram__v1 
                = (0xffU & (vlTOPp->dioptase__DOT__cpu__DOT__store_data 
                            >> 8U));
            __Vdlyvset__dioptase__DOT__mem__DOT__ram__v1 = 1U;
            __Vdlyvlsb__dioptase__DOT__mem__DOT__ram__v1 = 8U;
            __Vdlyvdim0__dioptase__DOT__mem__DOT__ram__v1 
                = (0xffffU & (vlTOPp->dioptase__DOT__cpu__DOT__tlb_out_1 
                              >> 2U));
        }
        if ((4U & (IData)(vlTOPp->dioptase__DOT__mem_write_en))) {
            __Vdlyvval__dioptase__DOT__mem__DOT__ram__v2 
                = (0xffU & (vlTOPp->dioptase__DOT__cpu__DOT__store_data 
                            >> 0x10U));
            __Vdlyvset__dioptase__DOT__mem__DOT__ram__v2 = 1U;
            __Vdlyvlsb__dioptase__DOT__mem__DOT__ram__v2 = 0x10U;
            __Vdlyvdim0__dioptase__DOT__mem__DOT__ram__v2 
                = (0xffffU & (vlTOPp->dioptase__DOT__cpu__DOT__tlb_out_1 
                              >> 2U));
        }
        if ((8U & (IData)(vlTOPp->dioptase__DOT__mem_write_en))) {
            __Vdlyvval__dioptase__DOT__mem__DOT__ram__v3 
                = (0xffU & (vlTOPp->dioptase__DOT__cpu__DOT__store_data 
                            >> 0x18U));
            __Vdlyvset__dioptase__DOT__mem__DOT__ram__v3 = 1U;
            __Vdlyvlsb__dioptase__DOT__mem__DOT__ram__v3 = 0x18U;
            __Vdlyvdim0__dioptase__DOT__mem__DOT__ram__v3 
                = (0xffffU & (vlTOPp->dioptase__DOT__cpu__DOT__tlb_out_1 
                              >> 2U));
        }
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__writeback__DOT__addr_buf 
            = vlTOPp->dioptase__DOT__cpu__DOT__mem_addr_out;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_is_load_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_is_load_out;
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_is_post_inc_out 
                    = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__is_absolute_mem) 
                       & (2U == (3U & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                       >> 0xeU))));
            }
        }
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
            = ((IData)(4U) + vlTOPp->dioptase__DOT__cpu__DOT__addr);
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall) 
                          & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__was_stall))))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_buf 
                    = vlTOPp->dioptase__DOT__mem_read0_data;
            }
            vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__was_was_stall 
                = vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__was_stall;
        }
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__writeback__DOT__was_misaligned 
            = vlTOPp->dioptase__DOT__cpu__DOT__mem_is_misaligned_out;
    }
    if (vlTOPp->dioptase__DOT__clk_en) {
        if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT____Vcellinp__fetch_a____pinNumber3)))) {
            vlTOPp->dioptase__DOT__cpu__DOT__fetch_a__DOT__pc 
                = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb)
                    ? vlTOPp->dioptase__DOT__mem_read1_data
                    : ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb)
                        ? vlTOPp->dioptase__DOT__cpu__DOT__mem_op1_out
                        : ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__branch)
                            ? ((IData)(4U) + vlTOPp->dioptase__DOT__cpu__DOT__branch_tgt)
                            : ((IData)(4U) + vlTOPp->dioptase__DOT__cpu__DOT__fetch_a__DOT__pc))));
        }
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_imm_out 
                    = vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__imm;
            }
        }
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out 
                    = vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__alu_op;
            }
        }
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out 
                    = vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__s_2;
            }
        }
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out 
                    = vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__s_1;
            }
        }
    }
    if (vlTOPp->dioptase__DOT__clk_en) {
        if (((IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_tlb_we_out) 
             & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_tlbc_out)))) {
            __Vdlyvval__dioptase__DOT__cpu__DOT__tlb__DOT__cache__v0 
                = (0x4000000000ULL | (((QData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_op1)) 
                                       << 6U) | (QData)((IData)(
                                                                (0x3fU 
                                                                 & vlTOPp->dioptase__DOT__cpu__DOT__exec_op2)))));
            __Vdlyvset__dioptase__DOT__cpu__DOT__tlb__DOT__cache__v0 = 1U;
            __Vdlyvdim0__dioptase__DOT__cpu__DOT__tlb__DOT__cache__v0 
                = vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__eviction_tgt;
            vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__eviction_tgt 
                = (7U & ((IData)(1U) + (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__eviction_tgt)));
        } else {
            if (vlTOPp->dioptase__DOT__cpu__DOT__decode_tlbc_out) {
                __Vdlyvset__dioptase__DOT__cpu__DOT__tlb__DOT__cache__v1 = 1U;
            }
        }
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
        vlTOPp->dioptase__DOT__cpu__DOT__decode_op1_out 
            = ((0U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__s_1))
                ? 0U : vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile
               [vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__s_1]);
        vlTOPp->dioptase__DOT__cpu__DOT__decode_op2_out 
            = ((0U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__s_2))
                ? 0U : vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile
               [vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__s_2]);
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        if (vlTOPp->dioptase__DOT__cpu__DOT__stall) {
            vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_b_1 
                = vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_a_1;
        }
    }
    if (vlTOPp->dioptase__DOT__clk_en) {
        vlTOPp->dioptase__DOT__cpu__DOT__halt = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt)
                                                  ? 1U
                                                  : 
                                                 (1U 
                                                  & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__wb_halt)));
        vlTOPp->dioptase__DOT__cpu__DOT__sleep = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__sleep) 
                                                  | (((((0x1fU 
                                                         == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)) 
                                                        & (2U 
                                                           == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_priv_type_out))) 
                                                       & (1U 
                                                          == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_crmov_mode_type_out))) 
                                                      & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_bubble_out))) 
                                                     & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb))));
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        if (vlTOPp->dioptase__DOT__cpu__DOT__stall) {
            vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_b_2 
                = vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_a_2;
        }
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        if (vlTOPp->dioptase__DOT__cpu__DOT__stall) {
            vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_b_1 
                = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)
                    ? (0x1fU & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_a_1))
                    : 0U);
        }
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        if (vlTOPp->dioptase__DOT__cpu__DOT__stall) {
            vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_b_2 
                = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)
                    ? (0x1fU & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_a_2))
                    : 0U);
        }
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_result_out_1 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_result_out_1;
    }
    if ((((((0U != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_1)) 
            & ((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_is_store_out)) 
               & (0xcU != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)))) 
           & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_bubble_out))) 
          & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_tgts_cr_out))) 
         & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb)))) {
        __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v0 
            = vlTOPp->dioptase__DOT__cpu__DOT__reg_write_data_1;
        __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v0 = 1U;
        __Vdlyvdim0__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v0 
            = vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_1;
    }
    if ((((((0U != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_2)) 
            & (0xcU != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out))) 
           & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_bubble_out))) 
          & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb))) 
         & ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_1) 
            != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_2)))) {
        __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v1 
            = vlTOPp->dioptase__DOT__cpu__DOT__mem_result_out_2;
        __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v1 = 1U;
        __Vdlyvdim0__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v1 
            = vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_2;
    }
    if (__Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v0) {
        vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile[__Vdlyvdim0__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v0] 
            = __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v0;
    }
    if (__Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v1) {
        vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile[__Vdlyvdim0__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v1] 
            = __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile__v1;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_is_load_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__decode_is_load_out;
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__was_stall 
                = vlTOPp->dioptase__DOT__cpu__DOT__stall;
        }
    }
    if (vlTOPp->dioptase__DOT__clk_en) {
        vlTOPp->dioptase__DOT__mem_read0_data = vlTOPp->dioptase__DOT__mem__DOT__data0_out;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_is_misaligned_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_is_misaligned_out;
    }
    if (vlTOPp->dioptase__DOT__clk_en) {
        vlTOPp->dioptase__DOT__mem_read1_data = vlTOPp->dioptase__DOT__mem__DOT__data1_out;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_op1_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_op1_out;
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_tlb_we_out 
                    = (((0x1fU == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                            >> 0x1bU))) 
                        & (0U == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                           >> 0xcU)))) 
                       & (1U == (3U & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                       >> 0xaU))));
            }
        }
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_tlbc_out 
                    = (((0x1fU == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                            >> 0x1bU))) 
                        & (0U == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                           >> 0xcU)))) 
                       & (2U == (3U & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                       >> 0xaU))));
            }
        }
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        if (vlTOPp->dioptase__DOT__cpu__DOT__stall) {
            vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_a_1 
                = vlTOPp->dioptase__DOT__cpu__DOT__wb_result_out_1;
        }
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_priv_type_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_priv_type_out;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        if (vlTOPp->dioptase__DOT__cpu__DOT__stall) {
            vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_a_2 
                = vlTOPp->dioptase__DOT__cpu__DOT__wb_result_out_2;
        }
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        if (vlTOPp->dioptase__DOT__cpu__DOT__stall) {
            vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_a_1 
                = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)
                    ? (0x1fU & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__wb_tgt_out_1))
                    : 0U);
        }
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        if (vlTOPp->dioptase__DOT__cpu__DOT__stall) {
            vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_a_2 
                = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)
                    ? (0x1fU & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__wb_tgt_out_2))
                    : 0U);
        }
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_result_out_1 
            = (((0xdU == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
                | (0xeU == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)))
                ? ((IData)(4U) + vlTOPp->dioptase__DOT__cpu__DOT__decode_pc_out)
                : ((((0x1fU == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
                     & (1U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_priv_type_out))) 
                    & (1U <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_crmov_mode_type_out)))
                    ? vlTOPp->dioptase__DOT__cpu__DOT__decode_cr_op_out
                    : ((((0x1fU == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
                         & (1U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_priv_type_out))) 
                        & (0U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_crmov_mode_type_out)))
                        ? vlTOPp->dioptase__DOT__cpu__DOT__exec_op1
                        : ((((0x1fU == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
                             & (0U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_priv_type_out))) 
                            & (0U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_crmov_mode_type_out)))
                            ? (0x3fU & ((0U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr2_index))
                                         ? (IData)(
                                                   vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                   [0U])
                                         : ((1U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr2_index))
                                             ? (IData)(
                                                       vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                       [1U])
                                             : ((2U 
                                                 == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr2_index))
                                                 ? (IData)(
                                                           vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                           [2U])
                                                 : 
                                                ((3U 
                                                  == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr2_index))
                                                  ? (IData)(
                                                            vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                            [3U])
                                                  : 
                                                 ((4U 
                                                   == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr2_index))
                                                   ? (IData)(
                                                             vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                             [4U])
                                                   : 
                                                  ((5U 
                                                    == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr2_index))
                                                    ? (IData)(
                                                              vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                              [5U])
                                                    : 
                                                   ((6U 
                                                     == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr2_index))
                                                     ? (IData)(
                                                               vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                               [6U])
                                                     : 
                                                    ((7U 
                                                      == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr2_index))
                                                      ? (IData)(
                                                                vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                [7U])
                                                      : 0U)))))))))
                            : vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__alu_rslt))));
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_is_store_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_is_store_out;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_opcode_out;
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_is_load_out 
                    = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__is_mem) 
                       & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__load_bit));
            }
        }
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_is_misaligned_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__is_misaligned;
    }
    if (vlTOPp->dioptase__DOT__clk_en) {
        vlTOPp->dioptase__DOT__mem__DOT__data0_out 
            = vlTOPp->dioptase__DOT__mem__DOT__ram[
            (0xffffU & ((((0x30000U > vlTOPp->dioptase__DOT__cpu__DOT__fetch_addr) 
                          & (0U != vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                             [0U])) ? vlTOPp->dioptase__DOT__cpu__DOT__fetch_addr
                          : ((0x3f000U & (((0U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr0_index))
                                            ? (IData)(
                                                      vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                      [0U])
                                            : ((1U 
                                                == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr0_index))
                                                ? (IData)(
                                                          vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                          [1U])
                                                : (
                                                   (2U 
                                                    == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr0_index))
                                                    ? (IData)(
                                                              vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                              [2U])
                                                    : 
                                                   ((3U 
                                                     == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr0_index))
                                                     ? (IData)(
                                                               vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                               [3U])
                                                     : 
                                                    ((4U 
                                                      == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr0_index))
                                                      ? (IData)(
                                                                vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                [4U])
                                                      : 
                                                     ((5U 
                                                       == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr0_index))
                                                       ? (IData)(
                                                                 vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                 [5U])
                                                       : 
                                                      ((6U 
                                                        == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr0_index))
                                                        ? (IData)(
                                                                  vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                  [6U])
                                                        : 
                                                       ((7U 
                                                         == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr0_index))
                                                         ? (IData)(
                                                                   vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                   [7U])
                                                         : 0U)))))))) 
                                          << 0xcU)) 
                             | (0xfffU & vlTOPp->dioptase__DOT__cpu__DOT__fetch_addr))) 
                        >> 2U))];
        vlTOPp->dioptase__DOT__mem__DOT__data1_out 
            = vlTOPp->dioptase__DOT__mem__DOT__ram[
            (0xffffU & (vlTOPp->dioptase__DOT__cpu__DOT__tlb_out_1 
                        >> 2U))];
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_op1_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_op1;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__wb_result_out_1 
            = vlTOPp->dioptase__DOT__cpu__DOT__reg_write_data_1;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_priv_type_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__decode_priv_type_out;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__wb_result_out_2 
            = vlTOPp->dioptase__DOT__cpu__DOT__mem_result_out_2;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__wb_tgt_out_1 
            = vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_1;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__wb_tgt_out_2 
            = vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_2;
    }
    if (vlTOPp->dioptase__DOT__cpu__DOT__mem_tgts_cr_out) {
        __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v0 
            = vlTOPp->dioptase__DOT__cpu__DOT__reg_write_data_1;
        __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v0 = 1U;
        __Vdlyvdim0__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v0 
            = (7U & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_1));
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
        if ((1U & ((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb)) 
                   & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb))))) {
            vlTOPp->dioptase__DOT__cpu__DOT__decode_cr_op_out 
                = ((0U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__r_b))
                    ? 0U : vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                   [(7U & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__r_b))]);
        } else {
            if (vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb) {
                if (((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb) 
                     & ((0x82U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_exc_out)) 
                        | (0x83U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_exc_out))))) {
                    __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v1 
                        = (0xfffffU & (vlTOPp->dioptase__DOT__cpu__DOT__mem_addr_out 
                                       >> 0xcU));
                    __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v1 = 1U;
                }
                if (((0xfU == (0xfU & ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_exc_out) 
                                       >> 4U))) & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_bubble_out)))) {
                    __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v2 
                        = (0x7fffffffU & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                           [3U]);
                    __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v2 = 1U;
                }
                __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v3 
                    = vlTOPp->dioptase__DOT__cpu__DOT__mem_pc_out;
                __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v3 = 1U;
                __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v4 
                    = vlTOPp->dioptase__DOT__cpu__DOT__mem_flags_out;
                __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v5 
                    = ((IData)(1U) + vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                       [0U]);
            } else {
                if (vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb) {
                    if (((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb) 
                           & ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_crmov_mode_type_out) 
                              >> 1U)) & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_bubble_out))) 
                         & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb)))) {
                        __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v6 
                            = (0x80000000U | vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                               [3U]);
                        __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v6 = 1U;
                    }
                    __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v7 
                        = (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                           [0U] - (IData)(1U));
                    __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v7 = 1U;
                }
            }
        }
        __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v8 
            = vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
            [2U];
        __Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v8 = 1U;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_is_store_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__decode_is_store_out;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_opcode_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out;
    }
    if (__Vdlyvset__dioptase__DOT__mem__DOT__ram__v0) {
        vlTOPp->dioptase__DOT__mem__DOT__ram[__Vdlyvdim0__dioptase__DOT__mem__DOT__ram__v0] 
            = (((~ ((IData)(0xffU) << (IData)(__Vdlyvlsb__dioptase__DOT__mem__DOT__ram__v0))) 
                & vlTOPp->dioptase__DOT__mem__DOT__ram
                [__Vdlyvdim0__dioptase__DOT__mem__DOT__ram__v0]) 
               | ((IData)(__Vdlyvval__dioptase__DOT__mem__DOT__ram__v0) 
                  << (IData)(__Vdlyvlsb__dioptase__DOT__mem__DOT__ram__v0)));
    }
    if (__Vdlyvset__dioptase__DOT__mem__DOT__ram__v1) {
        vlTOPp->dioptase__DOT__mem__DOT__ram[__Vdlyvdim0__dioptase__DOT__mem__DOT__ram__v1] 
            = (((~ ((IData)(0xffU) << (IData)(__Vdlyvlsb__dioptase__DOT__mem__DOT__ram__v1))) 
                & vlTOPp->dioptase__DOT__mem__DOT__ram
                [__Vdlyvdim0__dioptase__DOT__mem__DOT__ram__v1]) 
               | ((IData)(__Vdlyvval__dioptase__DOT__mem__DOT__ram__v1) 
                  << (IData)(__Vdlyvlsb__dioptase__DOT__mem__DOT__ram__v1)));
    }
    if (__Vdlyvset__dioptase__DOT__mem__DOT__ram__v2) {
        vlTOPp->dioptase__DOT__mem__DOT__ram[__Vdlyvdim0__dioptase__DOT__mem__DOT__ram__v2] 
            = (((~ ((IData)(0xffU) << (IData)(__Vdlyvlsb__dioptase__DOT__mem__DOT__ram__v2))) 
                & vlTOPp->dioptase__DOT__mem__DOT__ram
                [__Vdlyvdim0__dioptase__DOT__mem__DOT__ram__v2]) 
               | ((IData)(__Vdlyvval__dioptase__DOT__mem__DOT__ram__v2) 
                  << (IData)(__Vdlyvlsb__dioptase__DOT__mem__DOT__ram__v2)));
    }
    if (__Vdlyvset__dioptase__DOT__mem__DOT__ram__v3) {
        vlTOPp->dioptase__DOT__mem__DOT__ram[__Vdlyvdim0__dioptase__DOT__mem__DOT__ram__v3] 
            = (((~ ((IData)(0xffU) << (IData)(__Vdlyvlsb__dioptase__DOT__mem__DOT__ram__v3))) 
                & vlTOPp->dioptase__DOT__mem__DOT__ram
                [__Vdlyvdim0__dioptase__DOT__mem__DOT__ram__v3]) 
               | ((IData)(__Vdlyvval__dioptase__DOT__mem__DOT__ram__v3) 
                  << (IData)(__Vdlyvlsb__dioptase__DOT__mem__DOT__ram__v3)));
    }
    if (__Vdlyvset__dioptase__DOT__cpu__DOT__tlb__DOT__cache__v0) {
        vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[__Vdlyvdim0__dioptase__DOT__cpu__DOT__tlb__DOT__cache__v0] 
            = __Vdlyvval__dioptase__DOT__cpu__DOT__tlb__DOT__cache__v0;
    }
    if (__Vdlyvset__dioptase__DOT__cpu__DOT__tlb__DOT__cache__v1) {
        vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[0U] = 0ULL;
        vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[1U] = 0ULL;
        vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[2U] = 0ULL;
        vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[3U] = 0ULL;
        vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[4U] = 0ULL;
        vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[5U] = 0ULL;
        vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[6U] = 0ULL;
        vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[7U] = 0ULL;
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_priv_type_out 
                    = (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                >> 0xcU));
            }
        }
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_result_out_2 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_result_out_2;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_2 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_tgt_out_2;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_crmov_mode_type_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_crmov_mode_type_out;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_addr_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_addr_out;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_pc_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_pc_out;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_flags_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_flags_out;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_tgts_cr_out 
            = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_tgts_cr_out) 
               & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_bubble_out)));
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_bubble_out 
            = (((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb) 
                | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb))
                ? 1U : (1U & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_bubble_out)));
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_1 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_tgt_out_1;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_exc_out 
            = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_bubble_out)
                ? 0U : (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_exc_out));
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_is_store_out 
                    = vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__is_store;
            }
        }
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out 
                    = (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                >> 0x1bU));
            }
        }
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_result_out_2 
            = vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__alu_rslt;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_tgt_out_2 
            = ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb) 
                 | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb)) 
                | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall))
                ? 0U : (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_tgt_out_2));
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_crmov_mode_type_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__decode_crmov_mode_type_out;
    }
    vlTOPp->dioptase__DOT__cpu__DOT__writeback__DOT__masked_mem_result 
        = (((3U <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)) 
            & (5U >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)))
            ? vlTOPp->dioptase__DOT__mem_read1_data
            : (((((6U <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)) 
                  & (8U >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out))) 
                 & (~ (vlTOPp->dioptase__DOT__cpu__DOT__mem_addr_out 
                       >> 1U))) & (~ vlTOPp->dioptase__DOT__cpu__DOT__mem_addr_out))
                ? (0xffffU & vlTOPp->dioptase__DOT__mem_read1_data)
                : (((((6U <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)) 
                      & (8U >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out))) 
                     & (~ (vlTOPp->dioptase__DOT__cpu__DOT__mem_addr_out 
                           >> 1U))) & vlTOPp->dioptase__DOT__cpu__DOT__mem_addr_out)
                    ? (0xffffU & (vlTOPp->dioptase__DOT__mem_read1_data 
                                  >> 8U)) : ((((6U 
                                                <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)) 
                                               & (8U 
                                                  >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out))) 
                                              & (vlTOPp->dioptase__DOT__cpu__DOT__mem_addr_out 
                                                 >> 1U))
                                              ? (vlTOPp->dioptase__DOT__mem_read1_data 
                                                 >> 0x10U)
                                              : (((
                                                   ((9U 
                                                     <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)) 
                                                    & (0xbU 
                                                       >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out))) 
                                                   & (~ vlTOPp->dioptase__DOT__cpu__DOT__mem_addr_out)) 
                                                  & (~ 
                                                     (vlTOPp->dioptase__DOT__cpu__DOT__mem_addr_out 
                                                      >> 1U)))
                                                  ? 
                                                 (0xffU 
                                                  & vlTOPp->dioptase__DOT__mem_read1_data)
                                                  : 
                                                 (((((9U 
                                                      <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)) 
                                                     & (0xbU 
                                                        >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out))) 
                                                    & vlTOPp->dioptase__DOT__cpu__DOT__mem_addr_out) 
                                                   & (~ 
                                                      (vlTOPp->dioptase__DOT__cpu__DOT__mem_addr_out 
                                                       >> 1U)))
                                                   ? 
                                                  (0xffU 
                                                   & (vlTOPp->dioptase__DOT__mem_read1_data 
                                                      >> 8U))
                                                   : 
                                                  (((((9U 
                                                       <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)) 
                                                      & (0xbU 
                                                         >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out))) 
                                                     & (~ vlTOPp->dioptase__DOT__cpu__DOT__mem_addr_out)) 
                                                    & (vlTOPp->dioptase__DOT__cpu__DOT__mem_addr_out 
                                                       >> 1U))
                                                    ? 
                                                   (0xffU 
                                                    & (vlTOPp->dioptase__DOT__mem_read1_data 
                                                       >> 0x10U))
                                                    : 
                                                   (((((9U 
                                                        <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)) 
                                                       & (0xbU 
                                                          >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out))) 
                                                      & vlTOPp->dioptase__DOT__cpu__DOT__mem_addr_out) 
                                                     & (vlTOPp->dioptase__DOT__cpu__DOT__mem_addr_out 
                                                        >> 1U))
                                                     ? 
                                                    (0xffU 
                                                     & (vlTOPp->dioptase__DOT__mem_read1_data 
                                                        >> 0x18U))
                                                     : 0U))))))));
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_addr_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__addr;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_pc_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__decode_pc_out;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_flags_out 
            = vlTOPp->dioptase__DOT__flags;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_tgts_cr_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__decode_tgts_cr_out;
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_tgt_out_1 
            = ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb) 
                 | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb)) 
                | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall))
                ? 0U : (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_tgt_out_1));
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_bubble_out 
            = ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb) 
                 | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb)) 
                | ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall) 
                   & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__is_misaligned))))
                ? 1U : (1U & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_bubble_out)));
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_exc_out 
            = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_bubble_out)
                ? 0U : ((0U != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_tlb_1))
                         ? (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_tlb_1)
                         : (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_exc_out)));
    }
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__is_mem_b 
        = ((9U <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
           & (0xbU >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)));
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__is_mem_w 
        = ((3U <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
           & (5U >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)));
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__is_mem_d 
        = ((6U <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
           & (8U >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)));
    vlTOPp->dioptase__DOT__cpu__DOT__reg_write_data_1 
        = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_is_load_out)
            ? ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__writeback__DOT__was_misaligned)
                ? (((3U <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)) 
                    & (5U >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)))
                    ? ((1U & ((~ (vlTOPp->dioptase__DOT__cpu__DOT__writeback__DOT__addr_buf 
                                  >> 1U)) & vlTOPp->dioptase__DOT__cpu__DOT__writeback__DOT__addr_buf))
                        ? ((0xff000000U & (vlTOPp->dioptase__DOT__mem_read1_data 
                                           << 0x18U)) 
                           | (0xffffffU & (vlTOPp->dioptase__DOT__cpu__DOT__writeback__DOT__mem_result_buf 
                                           >> 8U)))
                        : ((1U & ((vlTOPp->dioptase__DOT__cpu__DOT__writeback__DOT__addr_buf 
                                   >> 1U) & (~ vlTOPp->dioptase__DOT__cpu__DOT__writeback__DOT__addr_buf)))
                            ? ((0xffff0000U & (vlTOPp->dioptase__DOT__mem_read1_data 
                                               << 0x10U)) 
                               | (0xffffU & (vlTOPp->dioptase__DOT__cpu__DOT__writeback__DOT__mem_result_buf 
                                             >> 0x10U)))
                            : ((1U & ((vlTOPp->dioptase__DOT__cpu__DOT__writeback__DOT__addr_buf 
                                       >> 1U) & vlTOPp->dioptase__DOT__cpu__DOT__writeback__DOT__addr_buf))
                                ? ((0xffffff00U & (vlTOPp->dioptase__DOT__mem_read1_data 
                                                   << 8U)) 
                                   | (0xffU & (vlTOPp->dioptase__DOT__cpu__DOT__writeback__DOT__mem_result_buf 
                                               >> 0x18U)))
                                : 2U))) : (((6U <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)) 
                                            & (8U >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)))
                                            ? ((0xff00U 
                                                & (vlTOPp->dioptase__DOT__mem_read1_data 
                                                   << 8U)) 
                                               | (0xffU 
                                                  & (vlTOPp->dioptase__DOT__cpu__DOT__writeback__DOT__mem_result_buf 
                                                     >> 0x18U)))
                                            : 1U)) : vlTOPp->dioptase__DOT__cpu__DOT__writeback__DOT__masked_mem_result)
            : vlTOPp->dioptase__DOT__cpu__DOT__mem_result_out_1);
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_tgt_out_2 
                    = ((1U & ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__flush) 
                                | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__fetch_b_bubble_out)) 
                               | (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__is_absolute_mem))) 
                              | (0U == (3U & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                              >> 0xeU)))))
                        ? 0U : (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__r_b));
            }
        }
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_crmov_mode_type_out 
                    = (3U & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                             >> 0xaU));
            }
        }
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_pc_out 
                    = vlTOPp->dioptase__DOT__cpu__DOT__fetch_b_pc_out;
            }
        }
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_bubble_out)))) {
        vlTOPp->dioptase__DOT__flags = (0xfU & ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb)
                                                 ? vlTOPp->dioptase__DOT__cpu__DOT__mem_op2_out
                                                 : 
                                                (((((1U 
                                                     & (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__alu_rslt 
                                                        >> 0x1fU)) 
                                                    != 
                                                    (1U 
                                                     & (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__s_2_for_o 
                                                        >> 0x1fU))) 
                                                   & ((1U 
                                                       & (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__s_2_for_o 
                                                          >> 0x1fU)) 
                                                      == 
                                                      (1U 
                                                       & (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                                          >> 0x1fU)))) 
                                                  << 3U) 
                                                 | ((4U 
                                                     & (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__alu_rslt 
                                                        >> 0x1dU)) 
                                                    | (((0U 
                                                         == vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__alu_rslt) 
                                                        << 1U) 
                                                       | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__c))))));
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_tgts_cr_out 
                    = (((0x1fU == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                            >> 0x1bU))) 
                        & (1U == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                           >> 0xcU)))) 
                       & ((0U == (3U & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                        >> 0xaU))) 
                          | (2U == (3U & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                          >> 0xaU)))));
            }
        }
    }
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_tgt_out_1 
                    = ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__flush) 
                         | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__fetch_b_bubble_out)) 
                        | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__is_store))
                        ? 0U : (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__r_a));
            }
        }
    }
    vlTOPp->dioptase__DOT__cpu__DOT__exec_op1 = ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_tgt_out_1) 
                                                   == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)) 
                                                  & (0U 
                                                     != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)))
                                                  ? vlTOPp->dioptase__DOT__cpu__DOT__exec_result_out_1
                                                  : 
                                                 ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_tgt_out_2) 
                                                    == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)) 
                                                   & (0U 
                                                      != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)))
                                                   ? vlTOPp->dioptase__DOT__cpu__DOT__exec_result_out_2
                                                   : 
                                                  ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_1) 
                                                     == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)) 
                                                    & (0U 
                                                       != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)))
                                                    ? vlTOPp->dioptase__DOT__cpu__DOT__mem_result_out_1
                                                    : 
                                                   ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_2) 
                                                      == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)) 
                                                     & (0U 
                                                        != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)))
                                                     ? vlTOPp->dioptase__DOT__cpu__DOT__mem_result_out_2
                                                     : 
                                                    ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__wb_tgt_out_1) 
                                                       == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)) 
                                                      & (0U 
                                                         != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)))
                                                      ? vlTOPp->dioptase__DOT__cpu__DOT__wb_result_out_1
                                                      : 
                                                     ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__wb_tgt_out_2) 
                                                        == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)) 
                                                       & (0U 
                                                          != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)))
                                                       ? vlTOPp->dioptase__DOT__cpu__DOT__wb_result_out_2
                                                       : 
                                                      ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_a_1) 
                                                         == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)) 
                                                        & (0U 
                                                           != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)))
                                                        ? vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_a_1
                                                        : 
                                                       ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_a_2) 
                                                          == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)) 
                                                         & (0U 
                                                            != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)))
                                                         ? vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_a_2
                                                         : 
                                                        ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_b_1) 
                                                           == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)) 
                                                          & (0U 
                                                             != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)))
                                                          ? vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_b_1
                                                          : 
                                                         ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_b_2) 
                                                            == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)) 
                                                           & (0U 
                                                              != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)))
                                                           ? vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_b_2
                                                           : vlTOPp->dioptase__DOT__cpu__DOT__decode_op1_out))))))))));
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & ((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)) 
                       | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__is_misaligned)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_exc_out 
                    = ((0U != vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                        ? ((0x8000U & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                            ? 0xffU : ((0x4000U & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                                        ? 0xfeU : (
                                                   (0x2000U 
                                                    & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                                                    ? 0xfdU
                                                    : 
                                                   ((0x1000U 
                                                     & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                                                     ? 0xfcU
                                                     : 
                                                    ((0x800U 
                                                      & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                                                      ? 0xfbU
                                                      : 
                                                     ((0x400U 
                                                       & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                                                       ? 0xfaU
                                                       : 
                                                      ((0x200U 
                                                        & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                                                        ? 0xf9U
                                                        : 
                                                       ((0x100U 
                                                         & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                                                         ? 0xf8U
                                                         : 
                                                        ((0x80U 
                                                          & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                                                          ? 0xf7U
                                                          : 
                                                         ((0x40U 
                                                           & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                                                           ? 0xf6U
                                                           : 
                                                          ((0x20U 
                                                            & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                                                            ? 0xf5U
                                                            : 
                                                           ((0x10U 
                                                             & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                                                             ? 0xf4U
                                                             : 
                                                            ((8U 
                                                              & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                                                              ? 0xf3U
                                                              : 
                                                             ((4U 
                                                               & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                                                               ? 0xf2U
                                                               : 
                                                              ((2U 
                                                                & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                                                                ? 0xf1U
                                                                : 
                                                               ((1U 
                                                                 & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state)
                                                                 ? 0xf0U
                                                                 : 0U))))))))))))))))
                        : ((0U != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__fetch_b_exc_out))
                            ? (IData)(vlTOPp->dioptase__DOT__cpu__DOT__fetch_b_exc_out)
                            : (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__exc_priv_instr)));
            }
        }
    }
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
        = (((IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__was_stall) 
            | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__was_was_stall))
            ? vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_buf
            : vlTOPp->dioptase__DOT__mem_read0_data);
    vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr2_index 
        = (((vlTOPp->dioptase__DOT__cpu__DOT__exec_op1 
             == (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                         [0U] >> 6U))) & (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                  [0U] 
                                                  >> 0x26U)))
            ? 0U : (((vlTOPp->dioptase__DOT__cpu__DOT__exec_op1 
                      == (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                  [1U] >> 6U))) & (IData)(
                                                          (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                           [1U] 
                                                           >> 0x26U)))
                     ? 1U : (((vlTOPp->dioptase__DOT__cpu__DOT__exec_op1 
                               == (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                           [2U] >> 6U))) 
                              & (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                         [2U] >> 0x26U)))
                              ? 2U : (((vlTOPp->dioptase__DOT__cpu__DOT__exec_op1 
                                        == (IData)(
                                                   (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                    [3U] 
                                                    >> 6U))) 
                                       & (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                  [3U] 
                                                  >> 0x26U)))
                                       ? 3U : (((vlTOPp->dioptase__DOT__cpu__DOT__exec_op1 
                                                 == (IData)(
                                                            (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                             [4U] 
                                                             >> 6U))) 
                                                & (IData)(
                                                          (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                           [4U] 
                                                           >> 0x26U)))
                                                ? 4U
                                                : (
                                                   ((vlTOPp->dioptase__DOT__cpu__DOT__exec_op1 
                                                     == (IData)(
                                                                (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                 [5U] 
                                                                 >> 6U))) 
                                                    & (IData)(
                                                              (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                               [5U] 
                                                               >> 0x26U)))
                                                    ? 5U
                                                    : 
                                                   (((vlTOPp->dioptase__DOT__cpu__DOT__exec_op1 
                                                      == (IData)(
                                                                 (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                  [6U] 
                                                                  >> 6U))) 
                                                     & (IData)(
                                                               (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                [6U] 
                                                                >> 0x26U)))
                                                     ? 6U
                                                     : 
                                                    (((vlTOPp->dioptase__DOT__cpu__DOT__exec_op1 
                                                       == (IData)(
                                                                  (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                   [7U] 
                                                                   >> 6U))) 
                                                      & (IData)(
                                                                (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                 [7U] 
                                                                 >> 0x26U)))
                                                      ? 7U
                                                      : 0xfU))))))));
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
        = (((1U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
            & (0x10U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out)))
            ? vlTOPp->dioptase__DOT__cpu__DOT__decode_imm_out
            : vlTOPp->dioptase__DOT__cpu__DOT__exec_op1);
    if (vlTOPp->dioptase__DOT__clk_en) {
        if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT____Vcellinp__fetch_b____pinNumber3)))) {
            vlTOPp->dioptase__DOT__cpu__DOT__fetch_b_pc_out 
                = vlTOPp->dioptase__DOT__cpu__DOT__fetch_a_pc_out;
        }
    }
    vlTOPp->dioptase__DOT__cpu__DOT__branch_tgt = (
                                                   (0xcU 
                                                    == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out))
                                                    ? 
                                                   ((IData)(4U) 
                                                    + 
                                                    (vlTOPp->dioptase__DOT__cpu__DOT__decode_pc_out 
                                                     + vlTOPp->dioptase__DOT__cpu__DOT__decode_imm_out))
                                                    : 
                                                   ((0xdU 
                                                     == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out))
                                                     ? vlTOPp->dioptase__DOT__cpu__DOT__exec_op1
                                                     : 
                                                    ((0xeU 
                                                      == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out))
                                                      ? 
                                                     ((IData)(4U) 
                                                      + 
                                                      (vlTOPp->dioptase__DOT__cpu__DOT__decode_pc_out 
                                                       + vlTOPp->dioptase__DOT__cpu__DOT__exec_op1))
                                                      : 
                                                     ((IData)(4U) 
                                                      + vlTOPp->dioptase__DOT__cpu__DOT__decode_pc_out))));
    if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)))) {
        if (vlTOPp->dioptase__DOT__clk_en) {
            if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)))) {
                vlTOPp->dioptase__DOT__cpu__DOT__decode_bubble_out 
                    = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__flush)
                        ? 1U : (1U & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__fetch_b_bubble_out)));
            }
        }
    }
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__taken 
        = ((0U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
            ? 1U : (1U & ((1U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                           ? (1U & ((IData)(vlTOPp->dioptase__DOT__flags) 
                                    >> 1U)) : ((2U 
                                                == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                ? (1U 
                                                   & (~ 
                                                      ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                       >> 1U)))
                                                : (
                                                   (3U 
                                                    == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                    ? 
                                                   (1U 
                                                    & ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                       >> 2U))
                                                    : 
                                                   ((4U 
                                                     == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                     ? 
                                                    (1U 
                                                     & (~ 
                                                        ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                         >> 2U)))
                                                     : 
                                                    ((5U 
                                                      == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                      ? 
                                                     (1U 
                                                      & (IData)(vlTOPp->dioptase__DOT__flags))
                                                      : 
                                                     ((6U 
                                                       == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                       ? 
                                                      (1U 
                                                       & (~ (IData)(vlTOPp->dioptase__DOT__flags)))
                                                       : 
                                                      ((7U 
                                                        == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                        ? 
                                                       (1U 
                                                        & ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                           >> 3U))
                                                        : 
                                                       ((8U 
                                                         == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                         ? 
                                                        (1U 
                                                         & (~ 
                                                            ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                             >> 3U)))
                                                         : 
                                                        ((9U 
                                                          == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                          ? 
                                                         (1U 
                                                          & ((~ 
                                                              ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                               >> 1U)) 
                                                             & (~ 
                                                                ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                 >> 2U))))
                                                          : 
                                                         ((0xaU 
                                                           == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                           ? 
                                                          (1U 
                                                           & (((IData)(vlTOPp->dioptase__DOT__flags) 
                                                               >> 1U) 
                                                              | ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                 >> 2U)))
                                                           : 
                                                          ((0xbU 
                                                            == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                            ? 
                                                           (((1U 
                                                              & ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                 >> 2U)) 
                                                             == 
                                                             (1U 
                                                              & ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                 >> 3U))) 
                                                            & (~ 
                                                               ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                >> 1U)))
                                                            : 
                                                           ((0xcU 
                                                             == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                             ? 
                                                            ((1U 
                                                              & ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                 >> 2U)) 
                                                             == 
                                                             (1U 
                                                              & ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                 >> 3U)))
                                                             : 
                                                            ((0xdU 
                                                              == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                              ? 
                                                             (((1U 
                                                                & ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                   >> 2U)) 
                                                               != 
                                                               (1U 
                                                                & ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                   >> 3U))) 
                                                              & (~ 
                                                                 ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                  >> 1U)))
                                                              : 
                                                             ((0xeU 
                                                               == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                               ? 
                                                              (1U 
                                                               & (((1U 
                                                                    & ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                       >> 2U)) 
                                                                   != 
                                                                   (1U 
                                                                    & ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                       >> 3U))) 
                                                                  | ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                     >> 1U)))
                                                               : 
                                                              ((0xfU 
                                                                == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                                ? 
                                                               (1U 
                                                                & ((~ 
                                                                    ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                     >> 1U)) 
                                                                   & (IData)(vlTOPp->dioptase__DOT__flags)))
                                                                : 
                                                               ((0x10U 
                                                                 == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                                 ? 
                                                                (1U 
                                                                 & ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                    | ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                       >> 1U)))
                                                                 : 
                                                                ((0x11U 
                                                                  == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                                  ? 
                                                                 (1U 
                                                                  & ((~ (IData)(vlTOPp->dioptase__DOT__flags)) 
                                                                     & (~ 
                                                                        ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                         >> 1U))))
                                                                  : 
                                                                 ((0x12U 
                                                                   == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_branch_code_out))
                                                                   ? 
                                                                  (1U 
                                                                   & ((~ (IData)(vlTOPp->dioptase__DOT__flags)) 
                                                                      | ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                         >> 1U)))
                                                                   : 0U))))))))))))))))))));
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__mem_op2_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_op2_out;
    }
    if (((0xdU == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                            >> 0x1bU))) | (0xeU == 
                                           (0x1fU & 
                                            (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                             >> 0x1bU))))) {
        vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__r_a 
            = (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                        >> 5U));
        vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__r_b 
            = (0x1fU & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in);
    } else {
        vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__r_a 
            = (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                        >> 0x16U));
        vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__r_b 
            = (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                        >> 0x11U));
    }
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__is_absolute_mem 
        = (((3U == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                             >> 0x1bU))) | (6U == (0x1fU 
                                                   & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                      >> 0x1bU)))) 
           | (9U == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                              >> 0x1bU))));
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__is_branch 
        = ((0xcU <= (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                              >> 0x1bU))) & (0xeU >= 
                                             (0x1fU 
                                              & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                 >> 0x1bU))));
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__load_bit 
        = (1U & ((((5U == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                    >> 0x1bU))) | (8U 
                                                   == 
                                                   (0x1fU 
                                                    & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                       >> 0x1bU)))) 
                  | (0xbU == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                       >> 0x1bU))))
                  ? (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                     >> 0x15U) : (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                  >> 0x10U)));
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__is_mem 
        = ((3U <= (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                            >> 0x1bU))) & (0xbU >= 
                                           (0x1fU & 
                                            (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                             >> 0x1bU))));
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__alu_op 
        = (0x1fU & ((0U == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                     >> 0x1bU))) ? 
                    (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                     >> 5U) : (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                               >> 0xcU)));
    if (vlTOPp->dioptase__DOT__clk_en) {
        if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT____Vcellinp__fetch_b____pinNumber3)))) {
            vlTOPp->dioptase__DOT__cpu__DOT__fetch_b_exc_out 
                = ((0U != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__fetch_a_exc_out))
                    ? (IData)(vlTOPp->dioptase__DOT__cpu__DOT__fetch_a_exc_out)
                    : ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__fetch_a_bubble_out)
                        ? 0U : (((0xfU == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr0_index)) 
                                 & (~ ((0x30000U > vlTOPp->dioptase__DOT__cpu__DOT__fetch_addr) 
                                       & (0U != vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                                          [0U])))) ? 
                                ((0U != vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                                  [0U]) ? 0x83U : 0x82U)
                                 : 0U)));
        }
    }
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__is_store 
        = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__is_mem) 
           & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__load_bit)));
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__s_1 
        = ((((((((2U == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                  >> 0x1bU))) | (5U 
                                                 == 
                                                 (0x1fU 
                                                  & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                     >> 0x1bU)))) 
                | (8U == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                   >> 0x1bU)))) | (0xbU 
                                                   == 
                                                   (0x1fU 
                                                    & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                       >> 0x1bU)))) 
              | (0xcU == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                   >> 0x1bU)))) | (0xfU 
                                                   == 
                                                   (0x1fU 
                                                    & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                       >> 0x1bU)))) 
            | (((0U == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                 >> 0x1bU))) | (1U 
                                                == 
                                                (0x1fU 
                                                 & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                    >> 0x1bU)))) 
               & (6U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__alu_op))))
            ? 0U : (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__r_b));
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__imm 
        = (((1U == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                             >> 0x1bU))) & (6U >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__alu_op)))
            ? ((0xffU & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in) 
               << (0x18U & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                            >> 5U))) : (((1U == (0x1fU 
                                                 & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                    >> 0x1bU))) 
                                         & ((7U <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__alu_op)) 
                                            & (0xdU 
                                               >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__alu_op))))
                                         ? (0x1fU & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in)
                                         : (((1U == 
                                              (0x1fU 
                                               & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                  >> 0x1bU))) 
                                             & ((0xeU 
                                                 <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__alu_op)) 
                                                & (0x12U 
                                                   >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__alu_op))))
                                             ? ((0xfffff000U 
                                                 & ((- (IData)(
                                                               (1U 
                                                                & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                                   >> 0xbU)))) 
                                                    << 0xcU)) 
                                                | (0xfffU 
                                                   & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in))
                                             : ((2U 
                                                 == 
                                                 (0x1fU 
                                                  & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                     >> 0x1bU)))
                                                 ? 
                                                (0xfffffc00U 
                                                 & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                    << 0xaU))
                                                 : 
                                                ((0xcU 
                                                  == 
                                                  (0x1fU 
                                                   & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                      >> 0x1bU)))
                                                  ? 
                                                 ((0xffc00000U 
                                                   & ((- (IData)(
                                                                 (1U 
                                                                  & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                                     >> 0x15U)))) 
                                                      << 0x16U)) 
                                                  | (0x3fffffU 
                                                     & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in))
                                                  : 
                                                 ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__is_absolute_mem)
                                                   ? 
                                                  (((0xfffff000U 
                                                     & ((- (IData)(
                                                                   (1U 
                                                                    & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                                       >> 0xbU)))) 
                                                        << 0xcU)) 
                                                    | (0xfffU 
                                                       & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in)) 
                                                   << 
                                                   (3U 
                                                    & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                       >> 0xcU)))
                                                   : 
                                                  ((((4U 
                                                      == 
                                                      (0x1fU 
                                                       & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                          >> 0x1bU))) 
                                                     | (7U 
                                                        == 
                                                        (0x1fU 
                                                         & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                            >> 0x1bU)))) 
                                                    | (0xaU 
                                                       == 
                                                       (0x1fU 
                                                        & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                           >> 0x1bU))))
                                                    ? 
                                                   ((0xffff0000U 
                                                     & ((- (IData)(
                                                                   (1U 
                                                                    & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                                       >> 0xfU)))) 
                                                        << 0x10U)) 
                                                    | (0xffffU 
                                                       & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in))
                                                    : 
                                                   ((((5U 
                                                       == 
                                                       (0x1fU 
                                                        & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                           >> 0x1bU))) 
                                                      | (8U 
                                                         == 
                                                         (0x1fU 
                                                          & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                             >> 0x1bU)))) 
                                                     | (0xbU 
                                                        == 
                                                        (0x1fU 
                                                         & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                            >> 0x1bU))))
                                                     ? 
                                                    ((0xffe00000U 
                                                      & ((- (IData)(
                                                                    (1U 
                                                                     & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                                                        >> 0x14U)))) 
                                                         << 0x15U)) 
                                                     | (0x1fffffU 
                                                        & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in))
                                                     : 0U))))))));
    if (vlTOPp->dioptase__DOT__clk_en) {
        if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT____Vcellinp__fetch_a____pinNumber3)))) {
            vlTOPp->dioptase__DOT__cpu__DOT__fetch_a_pc_out 
                = vlTOPp->dioptase__DOT__cpu__DOT__fetch_addr;
        }
    }
    if (vlTOPp->dioptase__DOT__clk_en) {
        if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT____Vcellinp__fetch_b____pinNumber3)))) {
            vlTOPp->dioptase__DOT__cpu__DOT__fetch_b_bubble_out 
                = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__flush)
                    ? 1U : (1U & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__fetch_a_bubble_out)));
        }
    }
    if (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep)) 
         & (IData)(vlTOPp->dioptase__DOT__clk_en))) {
        vlTOPp->dioptase__DOT__cpu__DOT__exec_op2_out 
            = vlTOPp->dioptase__DOT__cpu__DOT__exec_op2;
    }
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__s_2 
        = (0x1fU & (((IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__is_store) 
                     | (0x1fU == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                           >> 0x1bU))))
                     ? (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__r_a)
                     : ((0U == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                         >> 0x1bU)))
                         ? vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in
                         : 0U)));
    if (vlTOPp->dioptase__DOT__clk_en) {
        if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT____Vcellinp__fetch_a____pinNumber3)))) {
            vlTOPp->dioptase__DOT__cpu__DOT__fetch_a_exc_out 
                = ((0U != (3U & vlTOPp->dioptase__DOT__cpu__DOT__fetch_addr))
                    ? 0x84U : 0U);
        }
    }
    vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep 
        = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt) 
           | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__sleep));
    vlTOPp->dioptase__DOT__cpu__DOT__exec_op2 = ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_tgt_out_1) 
                                                   == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)) 
                                                  & (0U 
                                                     != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)))
                                                  ? vlTOPp->dioptase__DOT__cpu__DOT__exec_result_out_1
                                                  : 
                                                 ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_tgt_out_2) 
                                                    == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)) 
                                                   & (0U 
                                                      != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)))
                                                   ? vlTOPp->dioptase__DOT__cpu__DOT__exec_result_out_2
                                                   : 
                                                  ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_1) 
                                                     == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)) 
                                                    & (0U 
                                                       != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)))
                                                    ? vlTOPp->dioptase__DOT__cpu__DOT__mem_result_out_1
                                                    : 
                                                   ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_2) 
                                                      == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)) 
                                                     & (0U 
                                                        != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)))
                                                     ? vlTOPp->dioptase__DOT__cpu__DOT__mem_result_out_2
                                                     : 
                                                    ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__wb_tgt_out_1) 
                                                       == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)) 
                                                      & (0U 
                                                         != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)))
                                                      ? vlTOPp->dioptase__DOT__cpu__DOT__wb_result_out_1
                                                      : 
                                                     ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__wb_tgt_out_2) 
                                                        == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)) 
                                                       & (0U 
                                                          != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)))
                                                       ? vlTOPp->dioptase__DOT__cpu__DOT__wb_result_out_2
                                                       : 
                                                      ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_a_1) 
                                                         == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)) 
                                                        & (0U 
                                                           != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)))
                                                        ? vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_a_1
                                                        : 
                                                       ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_a_2) 
                                                          == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)) 
                                                         & (0U 
                                                            != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)))
                                                         ? vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_a_2
                                                         : 
                                                        ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_b_1) 
                                                           == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)) 
                                                          & (0U 
                                                             != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)))
                                                          ? vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_b_1
                                                          : 
                                                         ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_b_2) 
                                                            == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)) 
                                                           & (0U 
                                                              != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out)))
                                                           ? vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_b_2
                                                           : vlTOPp->dioptase__DOT__cpu__DOT__decode_op2_out))))))))));
    if (vlTOPp->dioptase__DOT__clk_en) {
        if ((1U & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT____Vcellinp__fetch_a____pinNumber3)))) {
            vlTOPp->dioptase__DOT__cpu__DOT__fetch_a_bubble_out 
                = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb) 
                   | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb));
        }
    }
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs 
        = (((((1U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
              & (0x10U != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))) 
             | (2U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out))) 
            | ((3U <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
               & (0xbU >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out))))
            ? vlTOPp->dioptase__DOT__cpu__DOT__decode_imm_out
            : (((1U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
                & (0x10U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out)))
                ? vlTOPp->dioptase__DOT__cpu__DOT__exec_op1
                : vlTOPp->dioptase__DOT__cpu__DOT__exec_op2));
    vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb = ((0U 
                                                   != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_exc_out)) 
                                                  & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_bubble_out)));
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__sum 
        = (0x1ffffffffULL & ((QData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs)) 
                             + (QData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))));
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__diff 
        = (0x1ffffffffULL & ((QData)((IData)(((IData)(1U) 
                                              + (~ vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)))) 
                             + (QData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs))));
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__carry_sum 
        = (0x1ffffffffULL & (((QData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs)) 
                              + (QData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))) 
                             + (QData)((IData)((1U 
                                                & (IData)(vlTOPp->dioptase__DOT__flags))))));
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__s_2_subb 
        = ((IData)(1U) + (~ (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs 
                             + (1U & (~ (IData)(vlTOPp->dioptase__DOT__flags))))));
    if ((vlTOPp->dioptase__DOT__cpu__DOT__clk_count 
         >= vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
         [6U])) {
        __Vdly__dioptase__DOT__cpu__DOT__clk_count = 0U;
        vlTOPp->dioptase__DOT__clk_en = 1U;
    } else {
        __Vdly__dioptase__DOT__cpu__DOT__clk_count 
            = ((IData)(1U) + vlTOPp->dioptase__DOT__cpu__DOT__clk_count);
        vlTOPp->dioptase__DOT__clk_en = 0U;
    }
    vlTOPp->dioptase__DOT__cpu__DOT__wb_halt = ((((
                                                   (0x1fU 
                                                    == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)) 
                                                   & (2U 
                                                      == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_priv_type_out))) 
                                                  & (2U 
                                                     == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_crmov_mode_type_out))) 
                                                 & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_bubble_out))) 
                                                & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb)));
    vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb = ((
                                                   ((0x1fU 
                                                     == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_opcode_out)) 
                                                    & (3U 
                                                       == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_priv_type_out))) 
                                                   & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_bubble_out))) 
                                                  & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb)));
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__s_2_for_o 
        = ((0x10U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
            ? ((IData)(1U) + (~ vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
            : ((0x11U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                ? vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__s_2_subb
                : vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs));
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__carry_diff 
        = (0x1ffffffffULL & ((QData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__s_2_subb)) 
                             + (QData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs))));
    vlTOPp->dioptase__DOT__cpu__DOT__clk_count = __Vdly__dioptase__DOT__cpu__DOT__clk_count;
    if (__Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v0) {
        vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[__Vdlyvdim0__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v0] 
            = __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v0;
    }
    if (__Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v1) {
        vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[7U] 
            = __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v1;
    }
    if (__Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v2) {
        vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[3U] 
            = __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v2;
    }
    if (__Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v3) {
        vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[4U] 
            = __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v3;
        vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[5U] 
            = __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v4;
        vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[0U] 
            = __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v5;
    }
    if (__Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v6) {
        vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[3U] 
            = __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v6;
    }
    if (__Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v7) {
        vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[0U] 
            = __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v7;
    }
    if (__Vdlyvset__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v8) {
        vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[2U] 
            = __Vdlyvval__dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile__v8;
    }
    vlTOPp->dioptase__DOT__cpu__DOT__branch = (((((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_bubble_out)) 
                                                  & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb))) 
                                                 & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb))) 
                                                & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__taken)) 
                                               & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_is_branch_out));
    if (((0U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
         | (1U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)))) {
        vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__c 
            = (1U & ((0U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                      ? 0U : ((1U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                               ? 0U : ((2U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                        ? 0U : ((3U 
                                                 == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                 ? 0U
                                                 : 
                                                ((4U 
                                                  == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                  ? 0U
                                                  : 
                                                 ((5U 
                                                   == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                   ? 0U
                                                   : 
                                                  ((6U 
                                                    == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                    ? 0U
                                                    : 
                                                   ((7U 
                                                     == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                     ? 
                                                    (1U 
                                                     & (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                                        >> 0x1fU))
                                                     : 
                                                    ((8U 
                                                      == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                      ? 
                                                     (1U 
                                                      & vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs)
                                                      : 
                                                     ((9U 
                                                       == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                       ? 
                                                      (1U 
                                                       & vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs)
                                                       : 
                                                      ((0xaU 
                                                        == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                        ? 
                                                       (1U 
                                                        & (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                                           >> 0x1fU))
                                                        : 
                                                       ((0xbU 
                                                         == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                         ? 
                                                        (1U 
                                                         & vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs)
                                                         : 
                                                        ((0xcU 
                                                          == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                          ? 
                                                         (1U 
                                                          & (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                                             >> 0x1fU))
                                                          : 
                                                         ((0xdU 
                                                           == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                           ? 
                                                          (1U 
                                                           & vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs)
                                                           : 
                                                          ((0xeU 
                                                            == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                            ? 
                                                           (1U 
                                                            & (IData)(
                                                                      (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__sum 
                                                                       >> 0x20U)))
                                                            : 
                                                           ((0xfU 
                                                             == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                             ? 
                                                            (1U 
                                                             & (IData)(
                                                                       (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__carry_sum 
                                                                        >> 0x20U)))
                                                             : 
                                                            ((0x10U 
                                                              == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                              ? 
                                                             (1U 
                                                              & (IData)(
                                                                        (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__diff 
                                                                         >> 0x20U)))
                                                              : 
                                                             ((0x11U 
                                                               == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                               ? 
                                                              (1U 
                                                               & (IData)(
                                                                         (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__carry_diff 
                                                                          >> 0x20U)))
                                                               : 0U)))))))))))))))))));
        vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__alu_rslt 
            = ((0U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                ? (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                   & vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                : ((1U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                    ? (~ (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                          & vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
                    : ((2U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                        ? (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                           | vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                        : ((3U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                            ? (~ (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                  | vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
                            : ((4U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                ? (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                   ^ vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                : ((5U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                    ? (~ (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                          ^ vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
                                    : ((6U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                        ? (~ vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                        : ((7U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                            ? ((0x1fU 
                                                >= vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                                ? (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                                   << vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                                : 0U)
                                            : ((8U 
                                                == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                ? (
                                                   (0x1fU 
                                                    >= vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                                    ? 
                                                   (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                                    >> vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                                    : 0U)
                                                : (
                                                   (9U 
                                                    == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                    ? (IData)(
                                                              ((0x3fU 
                                                                >= vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                                                ? 
                                                               ((((QData)((IData)(
                                                                                (- (IData)(
                                                                                (1U 
                                                                                & (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                                                                >> 0x1fU)))))) 
                                                                  << 0x20U) 
                                                                 | (QData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs))) 
                                                                >> vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                                                : 0ULL))
                                                    : 
                                                   ((0xaU 
                                                     == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                     ? 
                                                    (((0x1fU 
                                                       >= vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                                       ? 
                                                      (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                                       << vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                                       : 0U) 
                                                     | ((0x1fU 
                                                         >= 
                                                         ((IData)(0x20U) 
                                                          - vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
                                                         ? 
                                                        (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                                         >> 
                                                         ((IData)(0x20U) 
                                                          - vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
                                                         : 0U))
                                                     : 
                                                    ((0xbU 
                                                      == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                      ? 
                                                     (((0x1fU 
                                                        >= vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                                        ? 
                                                       (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                                        >> vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                                        : 0U) 
                                                      | ((0x1fU 
                                                          >= 
                                                          ((IData)(0x20U) 
                                                           - vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
                                                          ? 
                                                         (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                                          << 
                                                          ((IData)(0x20U) 
                                                           - vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
                                                          : 0U))
                                                      : 
                                                     ((0xcU 
                                                       == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                       ? 
                                                      ((((0x1fU 
                                                          >= vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                                          ? 
                                                         (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                                          << vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                                          : 0U) 
                                                        | ((0x1fU 
                                                            >= 
                                                            ((IData)(0x20U) 
                                                             - vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
                                                            ? 
                                                           ((0x80000000U 
                                                             & ((IData)(vlTOPp->dioptase__DOT__flags) 
                                                                << 0x1fU)) 
                                                            >> 
                                                            ((IData)(0x20U) 
                                                             - vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
                                                            : 0U)) 
                                                       | ((0x1fU 
                                                           >= 
                                                           ((IData)(0x21U) 
                                                            - vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
                                                           ? 
                                                          (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                                           >> 
                                                           ((IData)(0x21U) 
                                                            - vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
                                                           : 0U))
                                                       : 
                                                      ((0xdU 
                                                        == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                        ? 
                                                       ((((0x1fU 
                                                           >= vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                                           ? 
                                                          (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                                           >> vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                                           : 0U) 
                                                         | ((0x1fU 
                                                             >= 
                                                             ((IData)(0x20U) 
                                                              - vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
                                                             ? 
                                                            ((1U 
                                                              & (IData)(vlTOPp->dioptase__DOT__flags)) 
                                                             << 
                                                             ((IData)(0x20U) 
                                                              - vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
                                                             : 0U)) 
                                                        | ((0x1fU 
                                                            >= 
                                                            ((IData)(0x21U) 
                                                             - vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
                                                            ? 
                                                           (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                                            << 
                                                            ((IData)(0x21U) 
                                                             - vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
                                                            : 0U))
                                                        : 
                                                       ((0xeU 
                                                         == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                         ? (IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__sum)
                                                         : 
                                                        ((0xfU 
                                                          == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                          ? (IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__carry_sum)
                                                          : 
                                                         ((0x10U 
                                                           == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                           ? (IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__diff)
                                                           : 
                                                          ((0x11U 
                                                            == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                            ? (IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__carry_diff)
                                                            : 
                                                           ((0x12U 
                                                             == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                                                             ? 
                                                            (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                                                             * vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                                                             : 0U)))))))))))))))))));
    } else {
        vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__c 
            = (1U & (1U & (IData)(vlTOPp->dioptase__DOT__flags)));
        vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__alu_rslt 
            = ((2U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out))
                ? vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs
                : (((3U <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
                    & (0xbU >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)))
                    ? (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs 
                       + vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs)
                    : ((0xcU == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out))
                        ? 0U : (((0xdU == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
                                 | (0xeU == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)))
                                 ? vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs
                                 : 0U))));
    }
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state 
        = ((0x80000000U & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
            [3U]) ? (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                     [2U] & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                     [3U]) : 0U);
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__exc_priv_instr 
        = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__fetch_b_bubble_out)
            ? 0U : (((((((0x10U <= (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                             >> 0x1bU))) 
                         & (0x1eU >= (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                               >> 0x1bU)))) 
                        | (((0U == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                             >> 0x1bU))) 
                            | (1U == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                               >> 0x1bU)))) 
                           & (0x12U < (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__alu_op)))) 
                       | ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__is_branch) 
                          & (0x12U < (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                               >> 0x16U))))) 
                      | ((0xfU == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                            >> 0x1bU))) 
                         & (1U != (0xffU & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in)))) 
                     | ((0x1fU == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                            >> 0x1bU))) 
                        & (3U < (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                          >> 0xcU)))))
                     ? 0x80U : (((0x1fU == (0x1fU & 
                                            (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                             >> 0x1bU))) 
                                 & (0U == vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                                    [0U])) ? 0x81U : 
                                ((0xfU == (0x1fU & 
                                           (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                            >> 0x1bU)))
                                  ? (0xffU & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in)
                                  : 0U))));
    vlTOPp->dioptase__DOT__cpu__DOT__flush = ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__branch) 
                                                | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__wb_halt)) 
                                               | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb)) 
                                              | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb));
    vlTOPp->dioptase__DOT__cpu__DOT__addr = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_is_misaligned_out)
                                              ? vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf
                                              : (((
                                                   (3U 
                                                    == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
                                                   | (6U 
                                                      == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out))) 
                                                  | (9U 
                                                     == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)))
                                                  ? 
                                                 ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_is_post_inc_out)
                                                   ? vlTOPp->dioptase__DOT__cpu__DOT__exec_op1
                                                   : vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__alu_rslt)
                                                  : 
                                                 ((((4U 
                                                     == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
                                                    | (7U 
                                                       == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out))) 
                                                   | (0xaU 
                                                      == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)))
                                                   ? 
                                                  ((IData)(4U) 
                                                   + 
                                                   (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__alu_rslt 
                                                    + vlTOPp->dioptase__DOT__cpu__DOT__decode_pc_out))
                                                   : 
                                                  ((((5U 
                                                      == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
                                                     | (8U 
                                                        == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out))) 
                                                    | (0xbU 
                                                       == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)))
                                                    ? 
                                                   ((IData)(4U) 
                                                    + 
                                                    (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__alu_rslt 
                                                     + vlTOPp->dioptase__DOT__cpu__DOT__decode_pc_out))
                                                    : 0U))));
    vlTOPp->dioptase__DOT__cpu__DOT__store_data = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__is_mem_w)
                                                    ? 
                                                   ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_is_misaligned_out)
                                                     ? 
                                                    ((1U 
                                                      & ((~ 
                                                          (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
                                                           >> 1U)) 
                                                         & (~ vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf)))
                                                      ? 0U
                                                      : 
                                                     ((1U 
                                                       & ((~ 
                                                           (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
                                                            >> 1U)) 
                                                          & vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf))
                                                       ? 
                                                      (vlTOPp->dioptase__DOT__cpu__DOT__exec_op2 
                                                       >> 0x18U)
                                                       : 
                                                      ((1U 
                                                        & ((vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
                                                            >> 1U) 
                                                           & (~ vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf)))
                                                        ? 
                                                       (vlTOPp->dioptase__DOT__cpu__DOT__exec_op2 
                                                        >> 0x10U)
                                                        : 
                                                       ((1U 
                                                         & ((vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
                                                             >> 1U) 
                                                            & vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf))
                                                         ? 
                                                        (vlTOPp->dioptase__DOT__cpu__DOT__exec_op2 
                                                         >> 8U)
                                                         : 0U))))
                                                     : 
                                                    ((1U 
                                                      & ((~ 
                                                          (vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                           >> 1U)) 
                                                         & (~ vlTOPp->dioptase__DOT__cpu__DOT__addr)))
                                                      ? vlTOPp->dioptase__DOT__cpu__DOT__exec_op2
                                                      : 
                                                     ((1U 
                                                       & ((~ 
                                                           (vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                            >> 1U)) 
                                                          & vlTOPp->dioptase__DOT__cpu__DOT__addr))
                                                       ? 
                                                      (vlTOPp->dioptase__DOT__cpu__DOT__exec_op2 
                                                       << 8U)
                                                       : 
                                                      ((1U 
                                                        & ((vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                            >> 1U) 
                                                           & (~ vlTOPp->dioptase__DOT__cpu__DOT__addr)))
                                                        ? 
                                                       (vlTOPp->dioptase__DOT__cpu__DOT__exec_op2 
                                                        << 0x10U)
                                                        : 
                                                       ((1U 
                                                         & ((vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                             >> 1U) 
                                                            & vlTOPp->dioptase__DOT__cpu__DOT__addr))
                                                         ? 
                                                        (vlTOPp->dioptase__DOT__cpu__DOT__exec_op2 
                                                         << 0x18U)
                                                         : 0U)))))
                                                    : 
                                                   ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__is_mem_d)
                                                     ? 
                                                    ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_is_misaligned_out)
                                                      ? 
                                                     ((1U 
                                                       & ((~ 
                                                           (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
                                                            >> 1U)) 
                                                          & (~ vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf)))
                                                       ? 0U
                                                       : 
                                                      ((1U 
                                                        & ((~ 
                                                            (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
                                                             >> 1U)) 
                                                           & vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf))
                                                        ? 0U
                                                        : 
                                                       ((1U 
                                                         & ((vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
                                                             >> 1U) 
                                                            & (~ vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf)))
                                                         ? 0U
                                                         : 
                                                        ((1U 
                                                          & ((vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
                                                              >> 1U) 
                                                             & vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf))
                                                          ? 
                                                         (0xffU 
                                                          & (vlTOPp->dioptase__DOT__cpu__DOT__exec_op2 
                                                             >> 8U))
                                                          : 0U))))
                                                      : 
                                                     ((1U 
                                                       & ((~ 
                                                           (vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                            >> 1U)) 
                                                          & (~ vlTOPp->dioptase__DOT__cpu__DOT__addr)))
                                                       ? 
                                                      (0xffffU 
                                                       & vlTOPp->dioptase__DOT__cpu__DOT__exec_op2)
                                                       : 
                                                      ((1U 
                                                        & ((~ 
                                                            (vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                             >> 1U)) 
                                                           & vlTOPp->dioptase__DOT__cpu__DOT__addr))
                                                        ? 
                                                       (0xffff00U 
                                                        & (vlTOPp->dioptase__DOT__cpu__DOT__exec_op2 
                                                           << 8U))
                                                        : 
                                                       ((1U 
                                                         & ((vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                             >> 1U) 
                                                            & (~ vlTOPp->dioptase__DOT__cpu__DOT__addr)))
                                                         ? 
                                                        (0xffff0000U 
                                                         & (vlTOPp->dioptase__DOT__cpu__DOT__exec_op2 
                                                            << 0x10U))
                                                         : 
                                                        ((1U 
                                                          & ((vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                              >> 1U) 
                                                             & vlTOPp->dioptase__DOT__cpu__DOT__addr))
                                                          ? 
                                                         (0xff000000U 
                                                          & (vlTOPp->dioptase__DOT__cpu__DOT__exec_op2 
                                                             << 0x18U))
                                                          : 0U)))))
                                                     : 
                                                    ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__is_mem_b)
                                                      ? 
                                                     ((1U 
                                                       & ((~ 
                                                           (vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                            >> 1U)) 
                                                          & (~ vlTOPp->dioptase__DOT__cpu__DOT__addr)))
                                                       ? 
                                                      (0xffU 
                                                       & vlTOPp->dioptase__DOT__cpu__DOT__exec_op2)
                                                       : 
                                                      ((1U 
                                                        & ((~ 
                                                            (vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                             >> 1U)) 
                                                           & vlTOPp->dioptase__DOT__cpu__DOT__addr))
                                                        ? 
                                                       (0xff00U 
                                                        & (vlTOPp->dioptase__DOT__cpu__DOT__exec_op2 
                                                           << 8U))
                                                        : 
                                                       ((1U 
                                                         & ((vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                             >> 1U) 
                                                            & (~ vlTOPp->dioptase__DOT__cpu__DOT__addr)))
                                                         ? 
                                                        (0xff0000U 
                                                         & (vlTOPp->dioptase__DOT__cpu__DOT__exec_op2 
                                                            << 0x10U))
                                                         : 
                                                        ((1U 
                                                          & ((vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                              >> 1U) 
                                                             & vlTOPp->dioptase__DOT__cpu__DOT__addr))
                                                          ? 
                                                         (0xff000000U 
                                                          & (vlTOPp->dioptase__DOT__cpu__DOT__exec_op2 
                                                             << 0x18U))
                                                          : 0U))))
                                                      : 0U)));
    vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key1 
        = ((0xfff00000U & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                           [1U] << 0x14U)) | (0xfffffU 
                                              & (vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                 >> 0xcU)));
    vlTOPp->dioptase__DOT__cpu__DOT__is_misaligned 
        = ((((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__is_mem_d) 
               & (vlTOPp->dioptase__DOT__cpu__DOT__addr 
                  >> 1U)) & vlTOPp->dioptase__DOT__cpu__DOT__addr) 
             | ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__is_mem_w) 
                & ((vlTOPp->dioptase__DOT__cpu__DOT__addr 
                    >> 1U) | vlTOPp->dioptase__DOT__cpu__DOT__addr))) 
            & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_bubble_out))) 
           & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_is_misaligned_out)));
    vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr1_index 
        = (((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key1 
             == (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                         [0U] >> 6U))) & (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                  [0U] 
                                                  >> 0x26U)))
            ? 0U : (((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key1 
                      == (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                  [1U] >> 6U))) & (IData)(
                                                          (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                           [1U] 
                                                           >> 0x26U)))
                     ? 1U : (((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key1 
                               == (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                           [2U] >> 6U))) 
                              & (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                         [2U] >> 0x26U)))
                              ? 2U : (((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key1 
                                        == (IData)(
                                                   (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                    [3U] 
                                                    >> 6U))) 
                                       & (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                  [3U] 
                                                  >> 0x26U)))
                                       ? 3U : (((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key1 
                                                 == (IData)(
                                                            (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                             [4U] 
                                                             >> 6U))) 
                                                & (IData)(
                                                          (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                           [4U] 
                                                           >> 0x26U)))
                                                ? 4U
                                                : (
                                                   ((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key1 
                                                     == (IData)(
                                                                (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                 [5U] 
                                                                 >> 6U))) 
                                                    & (IData)(
                                                              (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                               [5U] 
                                                               >> 0x26U)))
                                                    ? 5U
                                                    : 
                                                   (((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key1 
                                                      == (IData)(
                                                                 (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                  [6U] 
                                                                  >> 6U))) 
                                                     & (IData)(
                                                               (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                [6U] 
                                                                >> 0x26U)))
                                                     ? 6U
                                                     : 
                                                    (((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key1 
                                                       == (IData)(
                                                                  (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                   [7U] 
                                                                   >> 6U))) 
                                                      & (IData)(
                                                                (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                 [7U] 
                                                                 >> 0x26U)))
                                                      ? 7U
                                                      : 0xfU))))))));
    vlTOPp->dioptase__DOT__cpu__DOT__stall = (((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb)) 
                                               & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb))) 
                                              & ((((((((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_tgt_out_1) 
                                                         == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)) 
                                                        | ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_tgt_out_1) 
                                                           == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out))) 
                                                       & (0U 
                                                          != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_tgt_out_1))) 
                                                      | ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_tgt_out_2) 
                                                           == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)) 
                                                          | ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_tgt_out_2) 
                                                             == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out))) 
                                                         & (0U 
                                                            != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_tgt_out_2)))) 
                                                     & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_is_load_out)) 
                                                    & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_bubble_out))) 
                                                   & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_bubble_out))) 
                                                  | ((((((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_1) 
                                                           == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)) 
                                                          | ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_1) 
                                                             == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out))) 
                                                         & (0U 
                                                            != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_1))) 
                                                        | ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_2) 
                                                             == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_1_out)) 
                                                            | ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_2) 
                                                               == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_s_2_out))) 
                                                           & (0U 
                                                              != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_2)))) 
                                                       & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_is_load_out)) 
                                                      & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_bubble_out))) 
                                                     & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_bubble_out)))) 
                                                 | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__is_misaligned)));
    vlTOPp->dioptase__DOT__cpu__DOT__exc_tlb_1 = ((0U 
                                                   != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_exc_out))
                                                   ? (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_exc_out)
                                                   : 
                                                  ((((0xfU 
                                                      == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr1_index)) 
                                                     & (~ 
                                                        ((0x30000U 
                                                          > vlTOPp->dioptase__DOT__cpu__DOT__addr) 
                                                         & (0U 
                                                            != 
                                                            vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                                                            [0U])))) 
                                                    & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_bubble_out)))
                                                    ? 
                                                   ((0U 
                                                     != 
                                                     vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                                                     [0U])
                                                     ? 0x83U
                                                     : 0x82U)
                                                    : 0U));
    vlTOPp->dioptase__DOT__cpu__DOT____Vcellinp__fetch_b____pinNumber3 
        = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall) 
           | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep));
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit 
        = ((((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_is_store_out) 
               & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_bubble_out))) 
              & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb))) 
             & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb))) 
            & (0U != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_exc_out))) 
           & ((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall)) 
              | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__is_misaligned)));
    vlTOPp->dioptase__DOT__cpu__DOT____Vcellinp__fetch_a____pinNumber3 
        = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__stall) 
           | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep));
    vlTOPp->dioptase__DOT__cpu__DOT__tlb_out_1 = (0x3ffffU 
                                                  & ((0U 
                                                      != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_tlb_1))
                                                      ? 
                                                     ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_tlb_1) 
                                                      << 2U)
                                                      : 
                                                     (((0x30000U 
                                                        > vlTOPp->dioptase__DOT__cpu__DOT__addr) 
                                                       & (0U 
                                                          != 
                                                          vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                                                          [0U]))
                                                       ? vlTOPp->dioptase__DOT__cpu__DOT__addr
                                                       : 
                                                      ((0x3f000U 
                                                        & (((0U 
                                                             == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr1_index))
                                                             ? (IData)(
                                                                       vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                       [0U])
                                                             : 
                                                            ((1U 
                                                              == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr1_index))
                                                              ? (IData)(
                                                                        vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                        [1U])
                                                              : 
                                                             ((2U 
                                                               == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr1_index))
                                                               ? (IData)(
                                                                         vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                         [2U])
                                                               : 
                                                              ((3U 
                                                                == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr1_index))
                                                                ? (IData)(
                                                                          vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                          [3U])
                                                                : 
                                                               ((4U 
                                                                 == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr1_index))
                                                                 ? (IData)(
                                                                           vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                           [4U])
                                                                 : 
                                                                ((5U 
                                                                  == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr1_index))
                                                                  ? (IData)(
                                                                            vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                            [5U])
                                                                  : 
                                                                 ((6U 
                                                                   == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr1_index))
                                                                   ? (IData)(
                                                                             vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                             [6U])
                                                                   : 
                                                                  ((7U 
                                                                    == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr1_index))
                                                                    ? (IData)(
                                                                              vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                              [7U])
                                                                    : 0U)))))))) 
                                                           << 0xcU)) 
                                                       | (0xfffU 
                                                          & vlTOPp->dioptase__DOT__cpu__DOT__addr)))));
    vlTOPp->dioptase__DOT__mem_write_en = (0xfU & ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__is_mem_w)
                                                    ? 
                                                   ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_is_misaligned_out)
                                                     ? 
                                                    ((1U 
                                                      & ((~ 
                                                          (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
                                                           >> 1U)) 
                                                         & (~ vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf)))
                                                      ? 0U
                                                      : 
                                                     ((1U 
                                                       & ((~ 
                                                           (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
                                                            >> 1U)) 
                                                          & vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf))
                                                       ? (IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit)
                                                       : 
                                                      ((1U 
                                                        & ((vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
                                                            >> 1U) 
                                                           & (~ vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf)))
                                                        ? 
                                                       (3U 
                                                        & (- (IData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit))))
                                                        : 
                                                       ((1U 
                                                         & ((vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
                                                             >> 1U) 
                                                            & vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf))
                                                         ? 
                                                        (7U 
                                                         & (- (IData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit))))
                                                         : 0U))))
                                                     : 
                                                    ((1U 
                                                      & ((~ 
                                                          (vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                           >> 1U)) 
                                                         & (~ vlTOPp->dioptase__DOT__cpu__DOT__addr)))
                                                      ? 
                                                     (- (IData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit)))
                                                      : 
                                                     ((1U 
                                                       & ((~ 
                                                           (vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                            >> 1U)) 
                                                          & vlTOPp->dioptase__DOT__cpu__DOT__addr))
                                                       ? 
                                                      (0xeU 
                                                       & ((- (IData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit))) 
                                                          << 1U))
                                                       : 
                                                      ((1U 
                                                        & ((vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                            >> 1U) 
                                                           & (~ vlTOPp->dioptase__DOT__cpu__DOT__addr)))
                                                        ? 
                                                       (0xcU 
                                                        & ((- (IData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit))) 
                                                           << 2U))
                                                        : 
                                                       ((1U 
                                                         & ((vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                             >> 1U) 
                                                            & vlTOPp->dioptase__DOT__cpu__DOT__addr))
                                                         ? 
                                                        ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit) 
                                                         << 3U)
                                                         : 0U)))))
                                                    : 
                                                   ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__is_mem_d)
                                                     ? 
                                                    ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__exec_is_misaligned_out)
                                                      ? 
                                                     ((1U 
                                                       & ((~ 
                                                           (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
                                                            >> 1U)) 
                                                          & (~ vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf)))
                                                       ? 0U
                                                       : 
                                                      ((1U 
                                                        & ((~ 
                                                            (vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
                                                             >> 1U)) 
                                                           & vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf))
                                                        ? 0U
                                                        : 
                                                       ((1U 
                                                         & ((vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
                                                             >> 1U) 
                                                            & (~ vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf)))
                                                         ? 0U
                                                         : 
                                                        ((1U 
                                                          & ((vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf 
                                                              >> 1U) 
                                                             & vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__addr_buf))
                                                          ? (IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit)
                                                          : 0U))))
                                                      : 
                                                     ((1U 
                                                       & ((~ 
                                                           (vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                            >> 1U)) 
                                                          & (~ vlTOPp->dioptase__DOT__cpu__DOT__addr)))
                                                       ? 
                                                      (3U 
                                                       & (- (IData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit))))
                                                       : 
                                                      ((1U 
                                                        & ((~ 
                                                            (vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                             >> 1U)) 
                                                           & vlTOPp->dioptase__DOT__cpu__DOT__addr))
                                                        ? 
                                                       (6U 
                                                        & ((- (IData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit))) 
                                                           << 1U))
                                                        : 
                                                       ((1U 
                                                         & ((vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                             >> 1U) 
                                                            & (~ vlTOPp->dioptase__DOT__cpu__DOT__addr)))
                                                         ? 
                                                        (0xcU 
                                                         & ((- (IData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit))) 
                                                            << 2U))
                                                         : 
                                                        ((1U 
                                                          & ((vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                              >> 1U) 
                                                             & vlTOPp->dioptase__DOT__cpu__DOT__addr))
                                                          ? 
                                                         ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit) 
                                                          << 3U)
                                                          : 0U)))))
                                                     : 
                                                    ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__is_mem_b)
                                                      ? 
                                                     ((1U 
                                                       & ((~ 
                                                           (vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                            >> 1U)) 
                                                          & (~ vlTOPp->dioptase__DOT__cpu__DOT__addr)))
                                                       ? (IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit)
                                                       : 
                                                      ((1U 
                                                        & ((~ 
                                                            (vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                             >> 1U)) 
                                                           & vlTOPp->dioptase__DOT__cpu__DOT__addr))
                                                        ? 
                                                       ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit) 
                                                        << 1U)
                                                        : 
                                                       ((1U 
                                                         & ((vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                             >> 1U) 
                                                            & (~ vlTOPp->dioptase__DOT__cpu__DOT__addr)))
                                                         ? 
                                                        ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit) 
                                                         << 2U)
                                                         : 
                                                        ((1U 
                                                          & ((vlTOPp->dioptase__DOT__cpu__DOT__addr 
                                                              >> 1U) 
                                                             & vlTOPp->dioptase__DOT__cpu__DOT__addr))
                                                          ? 
                                                         ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__we_bit) 
                                                          << 3U)
                                                          : 0U))))
                                                      : 0U))));
    vlTOPp->dioptase__DOT__cpu__DOT__fetch_addr = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__branch)
                                                    ? vlTOPp->dioptase__DOT__cpu__DOT__branch_tgt
                                                    : 
                                                   ((IData)(vlTOPp->dioptase__DOT__cpu__DOT____Vcellinp__fetch_a____pinNumber3)
                                                     ? 
                                                    (vlTOPp->dioptase__DOT__cpu__DOT__fetch_a__DOT__pc 
                                                     - (IData)(4U))
                                                     : vlTOPp->dioptase__DOT__cpu__DOT__fetch_a__DOT__pc));
    vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key0 
        = ((0xfff00000U & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                           [1U] << 0x14U)) | (0xfffffU 
                                              & (vlTOPp->dioptase__DOT__cpu__DOT__fetch_addr 
                                                 >> 0xcU)));
    vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__addr0_index 
        = (((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key0 
             == (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                         [0U] >> 6U))) & (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                  [0U] 
                                                  >> 0x26U)))
            ? 0U : (((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key0 
                      == (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                  [1U] >> 6U))) & (IData)(
                                                          (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                           [1U] 
                                                           >> 0x26U)))
                     ? 1U : (((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key0 
                               == (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                           [2U] >> 6U))) 
                              & (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                         [2U] >> 0x26U)))
                              ? 2U : (((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key0 
                                        == (IData)(
                                                   (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                    [3U] 
                                                    >> 6U))) 
                                       & (IData)((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                  [3U] 
                                                  >> 0x26U)))
                                       ? 3U : (((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key0 
                                                 == (IData)(
                                                            (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                             [4U] 
                                                             >> 6U))) 
                                                & (IData)(
                                                          (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                           [4U] 
                                                           >> 0x26U)))
                                                ? 4U
                                                : (
                                                   ((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key0 
                                                     == (IData)(
                                                                (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                 [5U] 
                                                                 >> 6U))) 
                                                    & (IData)(
                                                              (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                               [5U] 
                                                               >> 0x26U)))
                                                    ? 5U
                                                    : 
                                                   (((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key0 
                                                      == (IData)(
                                                                 (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                  [6U] 
                                                                  >> 6U))) 
                                                     & (IData)(
                                                               (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                [6U] 
                                                                >> 0x26U)))
                                                     ? 6U
                                                     : 
                                                    (((vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__key0 
                                                       == (IData)(
                                                                  (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                   [7U] 
                                                                   >> 6U))) 
                                                      & (IData)(
                                                                (vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache
                                                                 [7U] 
                                                                 >> 0x26U)))
                                                      ? 7U
                                                      : 0xfU))))))));
}

void Vcpu::_eval(Vcpu__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu::_eval\n"); );
    Vcpu* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_combo__TOP__2(vlSymsp);
    if (((IData)(vlTOPp->__VinpClk__TOP__dioptase__DOT__c0__DOT__theClock) 
         & (~ (IData)(vlTOPp->__Vclklast__TOP____VinpClk__TOP__dioptase__DOT__c0__DOT__theClock)))) {
        vlTOPp->_sequent__TOP__3(vlSymsp);
    }
    // Final
    vlTOPp->__Vclklast__TOP____VinpClk__TOP__dioptase__DOT__c0__DOT__theClock 
        = vlTOPp->__VinpClk__TOP__dioptase__DOT__c0__DOT__theClock;
    vlTOPp->__VinpClk__TOP__dioptase__DOT__c0__DOT__theClock 
        = vlTOPp->dioptase__DOT__c0__DOT__theClock;
}

VL_INLINE_OPT QData Vcpu::_change_request(Vcpu__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu::_change_request\n"); );
    Vcpu* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    return (vlTOPp->_change_request_1(vlSymsp));
}

VL_INLINE_OPT QData Vcpu::_change_request_1(Vcpu__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu::_change_request_1\n"); );
    Vcpu* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    // Change detection
    QData __req = false;  // Logically a bool
    __req |= ((vlTOPp->dioptase__DOT__c0__DOT__theClock ^ vlTOPp->__Vchglast__TOP__dioptase__DOT__c0__DOT__theClock));
    VL_DEBUG_IF( if(__req && ((vlTOPp->dioptase__DOT__c0__DOT__theClock ^ vlTOPp->__Vchglast__TOP__dioptase__DOT__c0__DOT__theClock))) VL_DBG_MSGF("        CHANGE: src/clock.v:5: dioptase.c0.theClock\n"); );
    // Final
    vlTOPp->__Vchglast__TOP__dioptase__DOT__c0__DOT__theClock 
        = vlTOPp->dioptase__DOT__c0__DOT__theClock;
    return __req;
}

#ifdef VL_DEBUG
void Vcpu::_eval_debug_assertions() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu::_eval_debug_assertions\n"); );
}
#endif  // VL_DEBUG
