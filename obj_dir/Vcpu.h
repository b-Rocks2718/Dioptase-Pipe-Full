// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Primary design header
//
// This header should be included by all source files instantiating the design.
// The class here is then constructed to instantiate the design.
// See the Verilator manual for examples.

#ifndef _VCPU_H_
#define _VCPU_H_  // guard

#include "verilated_heavy.h"

//==========

class Vcpu__Syms;

//----------

VL_MODULE(Vcpu) {
  public:
    
    // LOCAL SIGNALS
    // Internals; generally not touched by application code
    // Anonymous structures to workaround compiler member-count bugs
    struct {
        CData/*0:0*/ dioptase__DOT__c0__DOT__theClock;
        CData/*3:0*/ dioptase__DOT__mem_write_en;
        CData/*0:0*/ dioptase__DOT__clk_en;
        CData/*3:0*/ dioptase__DOT__flags;
        CData/*3:0*/ dioptase__DOT__cpu__DOT__mem_flags_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__halt;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__sleep;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__halt_or_sleep;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__branch;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__flush;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__wb_halt;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__exc_in_wb;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__rfe_in_wb;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__stall;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__fetch_a_bubble_out;
        CData/*7:0*/ dioptase__DOT__cpu__DOT__fetch_a_exc_out;
        CData/*7:0*/ dioptase__DOT__cpu__DOT__exc_tlb_1;
        CData/*7:0*/ dioptase__DOT__cpu__DOT__decode_exc_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__decode_tlb_we_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__decode_tlbc_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__decode_bubble_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__fetch_b_bubble_out;
        CData/*7:0*/ dioptase__DOT__cpu__DOT__fetch_b_exc_out;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__decode_opcode_out;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__decode_s_1_out;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__decode_s_2_out;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__decode_tgt_out_1;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__decode_tgt_out_2;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__decode_alu_op_out;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__decode_branch_code_out;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__mem_tgt_out_1;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__mem_tgt_out_2;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__decode_is_load_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__decode_is_store_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__decode_is_branch_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__decode_is_post_inc_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__decode_tgts_cr_out;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__decode_priv_type_out;
        CData/*1:0*/ dioptase__DOT__cpu__DOT__decode_crmov_mode_type_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__mem_tgts_cr_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__is_misaligned;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__exec_bubble_out;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__exec_opcode_out;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__exec_tgt_out_1;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__exec_tgt_out_2;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__wb_tgt_out_1;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__wb_tgt_out_2;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__mem_opcode_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__exec_is_load_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__exec_is_store_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__exec_is_misaligned_out;
        CData/*3:0*/ dioptase__DOT__cpu__DOT__exec_flags_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__exec_tgts_cr_out;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__exec_priv_type_out;
        CData/*1:0*/ dioptase__DOT__cpu__DOT__exec_crmov_mode_type_out;
        CData/*7:0*/ dioptase__DOT__cpu__DOT__exec_exc_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__mem_bubble_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__mem_is_load_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__mem_is_store_out;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__mem_is_misaligned_out;
        CData/*7:0*/ dioptase__DOT__cpu__DOT__mem_exc_out;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__mem_priv_type_out;
        CData/*1:0*/ dioptase__DOT__cpu__DOT__mem_crmov_mode_type_out;
        CData/*2:0*/ dioptase__DOT__cpu__DOT__tlb__DOT__eviction_tgt;
    };
    struct {
        CData/*3:0*/ dioptase__DOT__cpu__DOT__tlb__DOT__addr0_index;
        CData/*3:0*/ dioptase__DOT__cpu__DOT__tlb__DOT__addr1_index;
        CData/*3:0*/ dioptase__DOT__cpu__DOT__tlb__DOT__addr2_index;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__decode__DOT__was_stall;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__decode__DOT__was_was_stall;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__decode__DOT__r_a;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__decode__DOT__r_b;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__decode__DOT__alu_op;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__decode__DOT__load_bit;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__decode__DOT__is_mem;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__decode__DOT__is_branch;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__decode__DOT__is_store;
        CData/*7:0*/ dioptase__DOT__cpu__DOT__decode__DOT__exc_priv_instr;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__decode__DOT__is_absolute_mem;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__decode__DOT__s_1;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__decode__DOT__s_2;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_a_1;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_a_2;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_b_1;
        CData/*4:0*/ dioptase__DOT__cpu__DOT__execute__DOT__reg_tgt_buf_b_2;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__execute__DOT__is_mem_w;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__execute__DOT__is_mem_d;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__execute__DOT__is_mem_b;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__execute__DOT__we_bit;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__execute__DOT__taken;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__c;
        CData/*0:0*/ dioptase__DOT__cpu__DOT__writeback__DOT__was_misaligned;
        WData/*1023:0*/ dioptase__DOT__vcdfile[32];
        IData/*31:0*/ dioptase__DOT__mem_read0_data;
        IData/*31:0*/ dioptase__DOT__mem_read1_data;
        WData/*1023:0*/ dioptase__DOT__mem__DOT__hexfile[32];
        IData/*31:0*/ dioptase__DOT__mem__DOT__data0_out;
        IData/*31:0*/ dioptase__DOT__mem__DOT__data1_out;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__clk_count;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__mem_addr_out;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__fetch_addr;
        IData/*17:0*/ dioptase__DOT__cpu__DOT__tlb_out_1;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__exec_result_out_1;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__exec_result_out_2;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__addr;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__store_data;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__reg_write_data_1;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__branch_tgt;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__decode_pc_out;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__fetch_a_pc_out;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__mem_pc_out;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__decode_op1_out;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__decode_op2_out;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__exec_op1;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__exec_op2;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__mem_op1_out;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__mem_op2_out;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__fetch_b_pc_out;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__decode_imm_out;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__decode_cr_op_out;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__mem_result_out_1;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__mem_result_out_2;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__wb_result_out_1;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__wb_result_out_2;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__exec_addr_out;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__exec_pc_out;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__exec_op1_out;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__exec_op2_out;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__ctr__DOT__count;
    };
    struct {
        IData/*31:0*/ dioptase__DOT__cpu__DOT__tlb__DOT__key0;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__tlb__DOT__key1;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__fetch_a__DOT__pc;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__decode__DOT__instr_in;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__decode__DOT__instr_buf;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__decode__DOT__interrupt_state;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__decode__DOT__imm;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_a_1;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_a_2;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_b_1;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__execute__DOT__reg_data_buf_b_2;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__execute__DOT__addr_buf;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__execute__DOT__lhs;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__execute__DOT__rhs;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__execute__DOT__alu_rslt;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__s_2_subb;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__s_2_for_o;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__writeback__DOT__mem_result_buf;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__writeback__DOT__addr_buf;
        IData/*31:0*/ dioptase__DOT__cpu__DOT__writeback__DOT__masked_mem_result;
        QData/*32:0*/ dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__sum;
        QData/*32:0*/ dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__carry_sum;
        QData/*32:0*/ dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__diff;
        QData/*32:0*/ dioptase__DOT__cpu__DOT__execute__DOT__ALU__DOT__carry_diff;
        IData/*31:0*/ dioptase__DOT__mem__DOT__ram[65536];
        QData/*38:0*/ dioptase__DOT__cpu__DOT__tlb__DOT__cache[8];
        IData/*31:0*/ dioptase__DOT__cpu__DOT__decode__DOT__regfile__DOT__regfile[32];
        IData/*31:0*/ dioptase__DOT__cpu__DOT__decode__DOT__cregfile__DOT__cregfile[8];
    };
    
    // LOCAL VARIABLES
    // Internals; generally not touched by application code
    CData/*0:0*/ dioptase__DOT__cpu__DOT____Vcellinp__fetch_a____pinNumber3;
    CData/*0:0*/ dioptase__DOT__cpu__DOT____Vcellinp__fetch_b____pinNumber3;
    CData/*0:0*/ __VinpClk__TOP__dioptase__DOT__c0__DOT__theClock;
    CData/*0:0*/ __Vclklast__TOP____VinpClk__TOP__dioptase__DOT__c0__DOT__theClock;
    CData/*0:0*/ __Vchglast__TOP__dioptase__DOT__c0__DOT__theClock;
    
    // INTERNAL VARIABLES
    // Internals; generally not touched by application code
    Vcpu__Syms* __VlSymsp;  // Symbol table
    
    // CONSTRUCTORS
  private:
    VL_UNCOPYABLE(Vcpu);  ///< Copying not allowed
  public:
    /// Construct the model; called by application code
    /// The special name  may be used to make a wrapper with a
    /// single model invisible with respect to DPI scope names.
    Vcpu(const char* name = "TOP");
    /// Destroy the model; called (often implicitly) by application code
    ~Vcpu();
    
    // API METHODS
    /// Evaluate the model.  Application must call when inputs change.
    void eval() { eval_step(); }
    /// Evaluate when calling multiple units/models per time step.
    void eval_step();
    /// Evaluate at end of a timestep for tracing, when using eval_step().
    /// Application must call after all eval() and before time changes.
    void eval_end_step() {}
    /// Simulation complete, run final blocks.  Application must call on completion.
    void final();
    
    // INTERNAL METHODS
  private:
    static void _eval_initial_loop(Vcpu__Syms* __restrict vlSymsp);
  public:
    void __Vconfigure(Vcpu__Syms* symsp, bool first);
  private:
    static QData _change_request(Vcpu__Syms* __restrict vlSymsp);
    static QData _change_request_1(Vcpu__Syms* __restrict vlSymsp);
  public:
    static void _combo__TOP__2(Vcpu__Syms* __restrict vlSymsp);
  private:
    void _ctor_var_reset() VL_ATTR_COLD;
  public:
    static void _eval(Vcpu__Syms* __restrict vlSymsp);
  private:
#ifdef VL_DEBUG
    void _eval_debug_assertions();
#endif  // VL_DEBUG
  public:
    static void _eval_initial(Vcpu__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _eval_settle(Vcpu__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _initial__TOP__1(Vcpu__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _sequent__TOP__3(Vcpu__Syms* __restrict vlSymsp);
    static void _settle__TOP__4(Vcpu__Syms* __restrict vlSymsp) VL_ATTR_COLD;
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

//----------


#endif  // guard
