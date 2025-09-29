// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vcpu.h for the primary calling header

#include "Vcpu.h"
#include "Vcpu__Syms.h"

//==========

VL_CTOR_IMP(Vcpu) {
    Vcpu__Syms* __restrict vlSymsp = __VlSymsp = new Vcpu__Syms(this, name());
    Vcpu* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Reset internal values
    
    // Reset structure values
    _ctor_var_reset();
}

void Vcpu::__Vconfigure(Vcpu__Syms* vlSymsp, bool first) {
    if (false && first) {}  // Prevent unused
    this->__VlSymsp = vlSymsp;
    if (false && this->__VlSymsp) {}  // Prevent unused
    Verilated::timeunit(-12);
    Verilated::timeprecision(-12);
}

Vcpu::~Vcpu() {
    VL_DO_CLEAR(delete __VlSymsp, __VlSymsp = NULL);
}

void Vcpu::_initial__TOP__1(Vcpu__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu::_initial__TOP__1\n"); );
    Vcpu* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    if (VL_VALUEPLUSARGS_INW(1024,std::string("vcd=%s"),
                             vlTOPp->dioptase__DOT__vcdfile)) {
        vl_dumpctl_filenamep(true, VL_CVT_PACK_STR_NW(32, vlTOPp->dioptase__DOT__vcdfile));
    } else {
        vl_dumpctl_filenamep(true, std::string("cpu.vcd"));
    }
    VL_PRINTF_MT("-Info: src/top.v:15: $dumpvar ignored, as Verilated without --trace\n");
    vlTOPp->dioptase__DOT__c0__DOT__theClock = 1U;
    vlTOPp->dioptase__DOT__cpu__DOT__ctr__DOT__count = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__eviction_tgt = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__halt = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__sleep = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__wb_tgt_out_1 = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__wb_tgt_out_2 = 0U;
    if (VL_UNLIKELY((! VL_VALUEPLUSARGS_INW(1024,std::string("hex=%s"),
                                            vlTOPp->dioptase__DOT__mem__DOT__hexfile)))) {
        VL_WRITEF("ERROR: no +hex=<file> argument given!\n");
        VL_FINISH_MT("src/mem.v", 16, "");
    }
    VL_READMEM_N(true, 32, 65536, 0, VL_CVT_PACK_STR_NW(32, vlTOPp->dioptase__DOT__mem__DOT__hexfile)
                 , vlTOPp->dioptase__DOT__mem__DOT__ram
                 , 0, ~0ULL);
    vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[0U] = 0ULL;
    vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[1U] = 0ULL;
    vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[2U] = 0ULL;
    vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[3U] = 0ULL;
    vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[4U] = 0ULL;
    vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[5U] = 0ULL;
    vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[6U] = 0ULL;
    vlTOPp->dioptase__DOT__cpu__DOT__tlb__DOT__cache[7U] = 0ULL;
    vlTOPp->dioptase__DOT__cpu__DOT__mem_bubble_out = 1U;
    vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_1 = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__mem_tgt_out_2 = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__mem_exc_out = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__exec_bubble_out = 1U;
    vlTOPp->dioptase__DOT__cpu__DOT__exec_tgt_out_1 = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__exec_tgt_out_2 = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_a_1 = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_a_2 = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_b_1 = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_b_2 = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__exec_exc_out = 0U;
    vlTOPp->dioptase__DOT__flags = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__decode_bubble_out = 1U;
    vlTOPp->dioptase__DOT__cpu__DOT__decode_tgt_out_1 = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__decode_tgt_out_2 = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__decode_exc_out = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__fetch_b_bubble_out = 1U;
    vlTOPp->dioptase__DOT__cpu__DOT__fetch_b_exc_out = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__fetch_a_bubble_out = 1U;
    vlTOPp->dioptase__DOT__cpu__DOT__fetch_a__DOT__pc = 0x400U;
    vlTOPp->dioptase__DOT__cpu__DOT__fetch_a_exc_out = 0U;
    vlTOPp->dioptase__DOT__clk_en = 1U;
    vlTOPp->dioptase__DOT__cpu__DOT__clk_count = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[0U] = 1U;
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[1U] = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[2U] = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[3U] = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[4U] = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[5U] = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[6U] = 0U;
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[7U] = 0U;
}

void Vcpu::_settle__TOP__4(Vcpu__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu::_settle__TOP__4\n"); );
    Vcpu* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
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
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__is_mem_b 
        = ((9U <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
           & (0xbU >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)));
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__is_mem_w 
        = ((3U <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
           & (5U >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)));
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__is_mem_d 
        = ((6U <= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)) 
           & (8U >= (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_opcode_out)));
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
        = (((IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__was_stall) 
            | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__was_was_stall))
            ? vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_buf
            : vlTOPp->dioptase__DOT__mem_read0_data);
    vlTOPp->dioptase__DOT__c0__DOT__theClock = (1U 
                                                & (~ (IData)(vlTOPp->dioptase__DOT__c0__DOT__theClock)));
    vlTOPp->dioptase__DOT__cpu__DOT__halt_or_sleep 
        = ((IData)(vlTOPp->dioptase__DOT__cpu__DOT__halt) 
           | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__sleep));
    vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb = ((0U 
                                                   != (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_exc_out)) 
                                                  & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__mem_bubble_out)));
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
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state 
        = ((0x80000000U & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
            [3U]) ? (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                     [2U] & vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile
                     [3U]) : 0U);
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
    vlTOPp->dioptase__DOT__cpu__DOT__branch = (((((~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_bubble_out)) 
                                                  & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb))) 
                                                 & (~ (IData)(vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb))) 
                                                & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__taken)) 
                                               & (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_is_branch_out));
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
    vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__s_2 
        = (0x1fU & (((IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__is_store) 
                     | (0x1fU == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                           >> 0x1bU))))
                     ? (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__r_a)
                     : ((0U == (0x1fU & (vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in 
                                         >> 0x1bU)))
                         ? vlTOPp->dioptase__DOT__cpu__DOT__decode__DOT__instr_in
                         : 0U)));
    vlTOPp->dioptase__DOT__cpu__DOT__flush = ((((IData)(vlTOPp->dioptase__DOT__cpu__DOT__branch) 
                                                | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__wb_halt)) 
                                               | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__exc_in_wb)) 
                                              | (IData)(vlTOPp->dioptase__DOT__cpu__DOT__rfe_in_wb));
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__s_2_for_o 
        = ((0x10U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
            ? ((IData)(1U) + (~ vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs))
            : ((0x11U == (IData)(vlTOPp->dioptase__DOT__cpu__DOT__decode_alu_op_out))
                ? vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__s_2_subb
                : vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__rhs));
    vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__carry_diff 
        = (0x1ffffffffULL & ((QData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__s_2_subb)) 
                             + (QData)((IData)(vlTOPp->dioptase__DOT__cpu__DOT__execute__DOT__lhs))));
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

void Vcpu::_eval_initial(Vcpu__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu::_eval_initial\n"); );
    Vcpu* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_initial__TOP__1(vlSymsp);
    vlTOPp->__Vclklast__TOP____VinpClk__TOP__dioptase__DOT__c0__DOT__theClock 
        = vlTOPp->__VinpClk__TOP__dioptase__DOT__c0__DOT__theClock;
}

void Vcpu::final() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu::final\n"); );
    // Variables
    Vcpu__Syms* __restrict vlSymsp = this->__VlSymsp;
    Vcpu* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
}

void Vcpu::_eval_settle(Vcpu__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu::_eval_settle\n"); );
    Vcpu* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_settle__TOP__4(vlSymsp);
}

void Vcpu::_ctor_var_reset() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcpu::_ctor_var_reset\n"); );
    // Body
    VL_RAND_RESET_W(1024, dioptase__DOT__vcdfile);
    dioptase__DOT__mem_read0_data = VL_RAND_RESET_I(32);
    dioptase__DOT__mem_read1_data = VL_RAND_RESET_I(32);
    dioptase__DOT__mem_write_en = VL_RAND_RESET_I(4);
    dioptase__DOT__clk_en = VL_RAND_RESET_I(1);
    dioptase__DOT__flags = VL_RAND_RESET_I(4);
    dioptase__DOT__c0__DOT__theClock = VL_RAND_RESET_I(1);
    { int __Vi0=0; for (; __Vi0<65536; ++__Vi0) {
            dioptase__DOT__mem__DOT__ram[__Vi0] = VL_RAND_RESET_I(32);
    }}
    VL_RAND_RESET_W(1024, dioptase__DOT__mem__DOT__hexfile);
    dioptase__DOT__mem__DOT__data0_out = VL_RAND_RESET_I(32);
    dioptase__DOT__mem__DOT__data1_out = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__clk_count = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__mem_flags_out = VL_RAND_RESET_I(4);
    dioptase__DOT__cpu__DOT__mem_addr_out = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__halt = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__sleep = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__halt_or_sleep = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__fetch_addr = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__tlb_out_1 = VL_RAND_RESET_I(18);
    dioptase__DOT__cpu__DOT__exec_result_out_1 = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__exec_result_out_2 = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__addr = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__store_data = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__reg_write_data_1 = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__branch = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__flush = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__wb_halt = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__exc_in_wb = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__rfe_in_wb = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__stall = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__branch_tgt = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__decode_pc_out = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__fetch_a_pc_out = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__fetch_a_bubble_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__fetch_a_exc_out = VL_RAND_RESET_I(8);
    dioptase__DOT__cpu__DOT__exc_tlb_1 = VL_RAND_RESET_I(8);
    dioptase__DOT__cpu__DOT__mem_pc_out = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__decode_op1_out = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__decode_op2_out = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__exec_op1 = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__exec_op2 = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__decode_exc_out = VL_RAND_RESET_I(8);
    dioptase__DOT__cpu__DOT__decode_tlb_we_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__decode_tlbc_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__decode_bubble_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__mem_op1_out = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__mem_op2_out = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT____Vcellinp__fetch_a____pinNumber3 = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__fetch_b_bubble_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__fetch_b_pc_out = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__fetch_b_exc_out = VL_RAND_RESET_I(8);
    dioptase__DOT__cpu__DOT____Vcellinp__fetch_b____pinNumber3 = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__decode_opcode_out = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__decode_s_1_out = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__decode_s_2_out = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__decode_tgt_out_1 = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__decode_tgt_out_2 = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__decode_alu_op_out = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__decode_imm_out = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__decode_branch_code_out = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__mem_tgt_out_1 = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__mem_tgt_out_2 = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__decode_is_load_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__decode_is_store_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__decode_is_branch_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__decode_is_post_inc_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__decode_cr_op_out = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__decode_tgts_cr_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__decode_priv_type_out = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__decode_crmov_mode_type_out = VL_RAND_RESET_I(2);
    dioptase__DOT__cpu__DOT__mem_tgts_cr_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__is_misaligned = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__exec_bubble_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__mem_result_out_1 = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__mem_result_out_2 = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__exec_opcode_out = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__exec_tgt_out_1 = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__exec_tgt_out_2 = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__wb_tgt_out_1 = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__wb_tgt_out_2 = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__wb_result_out_1 = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__wb_result_out_2 = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__mem_opcode_out = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__exec_addr_out = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__exec_is_load_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__exec_is_store_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__exec_is_misaligned_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__exec_flags_out = VL_RAND_RESET_I(4);
    dioptase__DOT__cpu__DOT__exec_tgts_cr_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__exec_priv_type_out = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__exec_crmov_mode_type_out = VL_RAND_RESET_I(2);
    dioptase__DOT__cpu__DOT__exec_exc_out = VL_RAND_RESET_I(8);
    dioptase__DOT__cpu__DOT__exec_pc_out = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__exec_op1_out = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__exec_op2_out = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__mem_bubble_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__mem_is_load_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__mem_is_store_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__mem_is_misaligned_out = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__mem_exc_out = VL_RAND_RESET_I(8);
    dioptase__DOT__cpu__DOT__mem_priv_type_out = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__mem_crmov_mode_type_out = VL_RAND_RESET_I(2);
    dioptase__DOT__cpu__DOT__ctr__DOT__count = VL_RAND_RESET_I(32);
    { int __Vi0=0; for (; __Vi0<8; ++__Vi0) {
            dioptase__DOT__cpu__DOT__tlb__DOT__cache[__Vi0] = VL_RAND_RESET_Q(39);
    }}
    dioptase__DOT__cpu__DOT__tlb__DOT__eviction_tgt = VL_RAND_RESET_I(3);
    dioptase__DOT__cpu__DOT__tlb__DOT__key0 = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__tlb__DOT__key1 = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__tlb__DOT__addr0_index = VL_RAND_RESET_I(4);
    dioptase__DOT__cpu__DOT__tlb__DOT__addr1_index = VL_RAND_RESET_I(4);
    dioptase__DOT__cpu__DOT__tlb__DOT__addr2_index = VL_RAND_RESET_I(4);
    dioptase__DOT__cpu__DOT__fetch_a__DOT__pc = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__decode__DOT__was_stall = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__decode__DOT__was_was_stall = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__decode__DOT__instr_in = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__decode__DOT__instr_buf = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__decode__DOT__r_a = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__decode__DOT__r_b = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__decode__DOT__alu_op = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__decode__DOT__load_bit = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__decode__DOT__is_mem = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__decode__DOT__is_branch = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__decode__DOT__is_store = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__decode__DOT__exc_priv_instr = VL_RAND_RESET_I(8);
    dioptase__DOT__cpu__DOT__decode__DOT__is_absolute_mem = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__decode__DOT__s_1 = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__decode__DOT__s_2 = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__decode__DOT__imm = VL_RAND_RESET_I(32);
    { int __Vi0=0; for (; __Vi0<32; ++__Vi0) {
            dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile[__Vi0] = VL_RAND_RESET_I(32);
    }}
    { int __Vi0=0; for (; __Vi0<8; ++__Vi0) {
            dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[__Vi0] = VL_RAND_RESET_I(32);
    }}
    dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_a_1 = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_a_2 = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_b_1 = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_b_2 = VL_RAND_RESET_I(5);
    dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_a_1 = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_a_2 = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_b_1 = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_b_2 = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__execute__DOT__is_mem_w = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__execute__DOT__is_mem_d = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__execute__DOT__is_mem_b = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__execute__DOT__addr_buf = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__execute__DOT__lhs = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__execute__DOT__rhs = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__execute__DOT__we_bit = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__execute__DOT__alu_rslt = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__execute__DOT__taken = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__sum = VL_RAND_RESET_Q(33);
    dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__carry_sum = VL_RAND_RESET_Q(33);
    dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__s_2_subb = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__diff = VL_RAND_RESET_Q(33);
    dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__carry_diff = VL_RAND_RESET_Q(33);
    dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__c = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__s_2_for_o = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__writeback__DOT__was_misaligned = VL_RAND_RESET_I(1);
    dioptase__DOT__cpu__DOT__writeback__DOT__mem_result_buf = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__writeback__DOT__addr_buf = VL_RAND_RESET_I(32);
    dioptase__DOT__cpu__DOT__writeback__DOT__masked_mem_result = VL_RAND_RESET_I(32);
    __VinpClk__TOP__dioptase__DOT__c0__DOT__theClock = VL_RAND_RESET_I(1);
    __Vchglast__TOP__dioptase__DOT__c0__DOT__theClock = VL_RAND_RESET_I(1);
}
