/**
 *  vanilla_core_profiler.v
 *
 */

`include "definitions.vh"
`include "parameters.vh"

module vanilla_core_profiler
  #(parameter x_cord_width_p="inv"
    , parameter y_cord_width_p="inv"
    , parameter data_width_p="inv"
  )
  (
    input clk_i
    , input reset_i

    , input stall
    , input stall_depend
    , input stall_fp
    , input stall_ifetch_wait
    , input stall_icache_store
    , input stall_lr_aq
    , input stall_fence
    , input stall_md
    , input stall_force_wb
    , input stall_remote_req
    , input stall_local_flw

    //, input flush
    //, input id_signals_s id_r
    , input exe_signals_s exe_r
    , input fp_exe_signals_s fp_exe_r
    , input branch_mispredict
    , input jalr_mispredict
    , input fpu_float_ready_lo

    , input lsu_dmem_v_lo
    , input lsu_dmem_w_lo
  
    , input remote_req_s remote_req_o
    , input remote_req_v_o
    , input remote_req_yumi_i

    , input [x_cord_width_p-1:0] my_x_i
    , input [y_cord_width_p-1:0] my_y_i

    , input [31:0] global_ctr_i
    , input print_stat_v_i
    , input [data_width_p-1:0] print_stat_tag_i
  );


  // event signals
  //
  logic instr_inc;
  logic fp_instr_inc;

  //assign instr_inc = (~stall & ~stall_depend & ~flush)
  //  & (id_r.instruction != '0)
  //  & ~id_r.icache_miss;

  assign instr_inc = (~stall) & (exe_r.instruction != '0) & ~exe_r.icache_miss;
  assign fp_instr_inc = fp_exe_r.valid & fpu_float_ready_lo;

  // fp_float
  //
  logic fadd_inc;
  logic fsub_inc;
  logic fmul_inc;
  logic fsgnj_inc;
  logic fsgnjn_inc;
  logic fsgnjx_inc;
  logic fmin_inc;
  logic fmax_inc;
  logic fcvt_s_w_inc;
  logic fcvt_s_wu_inc;
  logic fmv_w_x_inc;

  assign fadd_inc = fp_instr_inc & fp_exe_r.fp_float_decode.fadd_op;
  assign fsub_inc = fp_instr_inc & fp_exe_r.fp_float_decode.fsub_op;
  assign fmul_inc = fp_instr_inc & fp_exe_r.fp_float_decode.fmul_op;
  assign fsgnj_inc = fp_instr_inc & fp_exe_r.fp_float_decode.fsgnj_op;
  assign fsgnjn_inc = fp_instr_inc & fp_exe_r.fp_float_decode.fsgnjn_op;
  assign fsgnjx_inc = fp_instr_inc & fp_exe_r.fp_float_decode.fsgnjx_op;
  assign fmin_inc = fp_instr_inc & fp_exe_r.fp_float_decode.fmin_op;
  assign fmax_inc = fp_instr_inc & fp_exe_r.fp_float_decode.fmax_op;
  assign fcvt_s_w_inc = fp_instr_inc & fp_exe_r.fp_float_decode.fcvt_s_w_op;
  assign fcvt_s_wu_inc = fp_instr_inc & fp_exe_r.fp_float_decode.fcvt_s_wu_op;
  assign fmv_w_x_inc = fp_instr_inc & fp_exe_r.fp_float_decode.fmv_w_x_op; 

  // fp_int
  //
  logic fp_int_inc; 
  logic feq_inc;
  logic flt_inc;
  logic fle_inc;
  logic fcvt_w_s_inc;
  logic fcvt_wu_s_inc;
  logic fclass_inc;
  logic fmv_x_w_inc;
  
  assign fp_int_inc = instr_inc & exe_r.decode.is_fp_int_op;
  assign feq_inc = fp_int_inc & exe_r.fp_int_decode.feq_op;
  assign flt_inc = fp_int_inc & exe_r.fp_int_decode.flt_op;
  assign fle_inc = fp_int_inc & exe_r.fp_int_decode.fle_op;
  assign fcvt_w_s_inc = fp_int_inc & exe_r.fp_int_decode.fcvt_w_s_op;
  assign fcvt_wu_s_inc = fp_int_inc & exe_r.fp_int_decode.fcvt_wu_s_op;
  assign fclass_inc = fp_int_inc & exe_r.fp_int_decode.fclass_op;
  assign fmv_x_w_inc = fp_int_inc & exe_r.fp_int_decode.fmv_x_w_op;

  // LSU
  //
  logic ld_inc;
  logic st_inc;
  logic remote_ld_inc;
  logic remote_st_inc;
  logic flw_inc;
  logic fsw_inc;
  logic remote_flw_inc;
  logic remote_fsw_inc;
  logic icache_miss_inc;
  
  assign ld_inc = lsu_dmem_v_lo & ~lsu_dmem_w_lo & ~stall & exe_r.decode.op_writes_rf;
  assign st_inc = lsu_dmem_v_lo & lsu_dmem_w_lo & ~stall & exe_r.decode.op_reads_rf2;
  assign remote_ld_inc = remote_req_v_o & remote_req_yumi_i & ~remote_req_o.write_not_read
    & ~remote_req_o.payload.read_info.load_info.icache_fetch
    & exe_r.decode.op_writes_rf;
  assign remote_st_inc = remote_req_v_o & remote_req_yumi_i & remote_req_o.write_not_read
    & exe_r.decode.op_reads_rf2;

  assign flw_inc = lsu_dmem_v_lo & ~lsu_dmem_w_lo & ~stall & exe_r.decode.op_writes_fp_rf;
  assign fsw_inc = lsu_dmem_v_lo & lsu_dmem_w_lo & ~stall & exe_r.decode.op_reads_fp_rf2;
  assign remote_flw_inc = remote_req_v_o & remote_req_yumi_i & ~remote_req_o.write_not_read
    & ~remote_req_o.payload.read_info.load_info.icache_fetch
    & exe_r.decode.op_writes_fp_rf;
  assign remote_fsw_inc = remote_req_v_o & remote_req_yumi_i & remote_req_o.write_not_read
    & exe_r.decode.op_reads_fp_rf2;

  assign icache_miss_inc = remote_req_v_o & remote_req_yumi_i & ~remote_req_o.write_not_read
    & remote_req_o.payload.read_info.load_info.icache_fetch;

  logic lr_inc;
  logic lr_aq_inc;
  logic swap_aq_inc;
  logic swap_rl_inc;

  assign lr_inc = instr_inc & exe_r.decode.op_is_lr;
  assign lr_aq_inc = instr_inc & exe_r.decode.op_is_lr_aq;
  assign swap_aq_inc = instr_inc & exe_r.decode.op_is_swap_aq;
  assign swap_rl_inc = instr_inc & exe_r.decode.op_is_swap_rl;


  // branch & jump
  //
  logic beq_inc;
  logic bne_inc;
  logic blt_inc;
  logic bge_inc;
  logic bltu_inc;
  logic bgeu_inc;
  logic jalr_inc;
  logic jal_inc;

  logic beq_miss_inc;
  logic bne_miss_inc;
  logic blt_miss_inc;
  logic bge_miss_inc;
  logic bltu_miss_inc;
  logic bgeu_miss_inc;
  logic jalr_miss_inc;

  assign beq_inc = instr_inc & exe_r.decode.is_branch_op & (exe_r.instruction ==? `RV32_BEQ);
  assign bne_inc = instr_inc & exe_r.decode.is_branch_op & (exe_r.instruction ==? `RV32_BNE);
  assign blt_inc = instr_inc & exe_r.decode.is_branch_op & (exe_r.instruction ==? `RV32_BLT);
  assign bge_inc = instr_inc & exe_r.decode.is_branch_op & (exe_r.instruction ==? `RV32_BGE);
  assign bltu_inc = instr_inc & exe_r.decode.is_branch_op & (exe_r.instruction ==? `RV32_BLTU);
  assign bgeu_inc = instr_inc & exe_r.decode.is_branch_op & (exe_r.instruction ==? `RV32_BGEU);

  assign jalr_inc = instr_inc & exe_r.decode.is_jump_op & (exe_r.instruction.op ==? `RV32_JALR_OP);
  assign jal_inc = instr_inc & exe_r.decode.is_jump_op & (exe_r.instruction.op ==? `RV32_JAL_OP);

  assign beq_miss_inc = beq_inc & branch_mispredict;
  assign bne_miss_inc = bne_inc & branch_mispredict;
  assign blt_miss_inc = blt_inc & branch_mispredict;
  assign bge_miss_inc = bge_inc & branch_mispredict;
  assign bltu_miss_inc = bltu_inc & branch_mispredict;
  assign bgeu_miss_inc = bgeu_inc & branch_mispredict;

  assign jalr_miss_inc = jalr_inc & jalr_mispredict;
  
  // ALU
  //
  logic sll_inc;
  logic slli_inc;
  logic srl_inc;
  logic srli_inc;
  logic sra_inc;
  logic srai_inc;
  
  logic add_inc;
  logic addi_inc;
  logic sub_inc;
  logic lui_inc;
  logic auipc_inc;

  logic xor_inc;
  logic xori_inc;
  logic or_inc;
  logic ori_inc;
  logic and_inc;
  logic andi_inc;
  
  logic slt_inc;
  logic slti_inc;
  logic sltu_inc;
  logic sltiu_inc;

  assign sll_inc = instr_inc & (exe_r.instruction ==? `RV32_SLL);
  assign slli_inc = instr_inc & (exe_r.instruction ==? `RV32_SLLI);
  assign srl_inc = instr_inc & (exe_r.instruction ==? `RV32_SRL);
  assign srli_inc = instr_inc & (exe_r.instruction ==? `RV32_SRLI);
  assign sra_inc = instr_inc & (exe_r.instruction ==? `RV32_SRA);
  assign srai_inc = instr_inc & (exe_r.instruction ==? `RV32_SRAI);

  assign add_inc = instr_inc & (exe_r.instruction ==? `RV32_ADD);
  assign addi_inc = instr_inc & (exe_r.instruction ==? `RV32_ADDI);
  assign sub_inc = instr_inc & (exe_r.instruction ==? `RV32_SUB);
  assign lui_inc = instr_inc & (exe_r.instruction ==? `RV32_LUI);
  assign auipc_inc = instr_inc & (exe_r.instruction ==? `RV32_AUIPC);
  assign xor_inc = instr_inc & (exe_r.instruction ==? `RV32_XOR);
  assign xori_inc = instr_inc & (exe_r.instruction ==? `RV32_XORI);
  assign or_inc = instr_inc & (exe_r.instruction ==? `RV32_OR);
  assign ori_inc = instr_inc & (exe_r.instruction ==? `RV32_ORI);
  assign and_inc = instr_inc & (exe_r.instruction ==? `RV32_AND);
  assign andi_inc = instr_inc & (exe_r.instruction ==? `RV32_ANDI);

  assign slt_inc = instr_inc & (exe_r.instruction ==? `RV32_SLT);
  assign slti_inc = instr_inc & (exe_r.instruction ==? `RV32_SLTI);
  assign sltu_inc = instr_inc & (exe_r.instruction ==? `RV32_SLTU);
  assign sltiu_inc = instr_inc & (exe_r.instruction ==? `RV32_SLTIU);


  // MULDIV
  //
  logic mul_inc;
  logic mulh_inc;
  logic mulhsu_inc;
  logic mulhu_inc;
  logic div_inc;
  logic divu_inc;
  logic rem_inc;
  logic remu_inc;

  assign mul_inc = instr_inc & (exe_r.instruction ==? `RV32_MUL);
  assign mulh_inc = instr_inc & (exe_r.instruction ==? `RV32_MULH);
  assign mulhsu_inc = instr_inc & (exe_r.instruction ==? `RV32_MULHSU);
  assign mulhu_inc = instr_inc & (exe_r.instruction ==? `RV32_MULHU);
  assign div_inc = instr_inc & (exe_r.instruction ==? `RV32_DIV);
  assign divu_inc = instr_inc & (exe_r.instruction ==? `RV32_DIVU);
  assign rem_inc = instr_inc & (exe_r.instruction ==? `RV32_REM);
  assign remu_inc = instr_inc & (exe_r.instruction ==? `RV32_REMU);

  // fence
  //
  logic fence_inc;
  assign fence_inc = instr_inc & exe_r.decode.is_fence_op;

  // stall
  //
  integer stall_fp_r;
  integer stall_depend_r;
  integer stall_ifetch_wait_r;
  integer stall_lr_aq_r;
  integer stall_fence_r;
  integer stall_md_r;
  integer stall_force_wb_r;
  integer stall_remote_req_r;
  integer stall_local_flw_r;
 
  logic stall_depend_inc;
  logic stall_fp_inc;
  logic stall_force_wb_inc;

  assign stall_depend_inc = stall_depend & ~(stall | stall_fp);
  assign stall_fp_inc = stall_fp & ~(stall | stall_depend);
  assign stall_force_wb_inc = stall_force_wb
    & ~(stall_ifetch_wait | stall_icache_store | stall_lr_aq
        | stall_fence | stall_md | stall_remote_req | stall_local_flw);

  //  profiling counters
  //
  typedef struct packed {
    integer cycle;
    integer instr;

    integer fadd;
    integer fsub;
    integer fmul;
    integer fsgnj;
    integer fsgnjn;
    integer fsgnjx;
    integer fmin;
    integer fmax;
    integer fcvt_s_w;
    integer fcvt_s_wu;
    integer fmv_w_x;

    integer feq;
    integer flt;
    integer fle;
    integer fcvt_w_s;
    integer fcvt_wu_s;
    integer fclass;
    integer fmv_x_w;

    integer ld;
    integer st;
    integer remote_ld;
    integer remote_st;
    integer flw;
    integer fsw;
    integer remote_flw;
    integer remote_fsw;
    integer icache_miss;

    integer lr;
    integer lr_aq;
    integer swap_aq;
    integer swap_rl;

    integer beq;
    integer bne;
    integer blt;
    integer bge;
    integer bltu;
    integer bgeu;
    integer jalr;
    integer jal;

    integer beq_miss;
    integer bne_miss;
    integer blt_miss;
    integer bge_miss;
    integer bltu_miss;
    integer bgeu_miss;
    integer jalr_miss;

    integer sll;
    integer slli;
    integer srl;
    integer srli;
    integer sra;
    integer srai;

    integer add;
    integer addi;
    integer sub;
    integer lui;
    integer auipc;
    integer xor_;
    integer xori;
    integer or_;
    integer ori;
    integer and_;
    integer andi;
    integer slt;
    integer slti;
    integer sltu;
    integer sltiu;

    integer mul;
    integer mulh;
    integer mulhsu;
    integer mulhu;
    integer div;
    integer divu;
    integer rem;
    integer remu;

    integer fence;

    integer stall_fp;
    integer stall_depend;
    integer stall_force_wb;
    integer stall_ifetch_wait;
    integer stall_icache_store;
    integer stall_lr_aq;
    integer stall_md; 
    integer stall_remote_req;
    integer stall_local_flw;
  
  } vanilla_stat_s;

  vanilla_stat_s curr_stat;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      curr_stat <= '0;
    end
    else begin
      curr_stat.cycle++;
      curr_stat.instr <= curr_stat.instr + instr_inc + fp_instr_inc;

      if (fadd_inc) curr_stat.fadd++;
      if (fsub_inc) curr_stat.fsub++;
      if (fmul_inc) curr_stat.fmul++;
      if (fsgnj_inc) curr_stat.fsgnj++;
      if (fsgnjn_inc) curr_stat.fsgnjn++;
      if (fsgnjx_inc) curr_stat.fsgnjx++;
      if (fmin_inc) curr_stat.fmin++;
      if (fmax_inc) curr_stat.fmax++;
      if (fcvt_s_w_inc) curr_stat.fcvt_s_w++;
      if (fcvt_s_wu_inc) curr_stat.fcvt_s_wu++;
      if (fmv_w_x_inc) curr_stat.fmv_w_x++;

      if (feq_inc) curr_stat.feq++;
      if (flt_inc) curr_stat.flt++;
      if (fle_inc) curr_stat.fle++;
      if (fcvt_w_s_inc) curr_stat.fcvt_w_s++;
      if (fcvt_wu_s_inc) curr_stat.fcvt_wu_s++;
      if (fclass_inc) curr_stat.fclass++;
      if (fmv_x_w_inc) curr_stat.fmv_x_w++;

      if (ld_inc) curr_stat.ld++;
      if (st_inc) curr_stat.st++;
      if (remote_ld_inc) curr_stat.remote_ld++;
      if (remote_st_inc) curr_stat.remote_st++;
      if (flw_inc) curr_stat.flw++;
      if (fsw_inc) curr_stat.fsw++;
      if (remote_flw_inc) curr_stat.remote_flw++;
      if (remote_fsw_inc) curr_stat.remote_fsw++;
      if (icache_miss_inc) curr_stat.icache_miss++;

      if (lr_inc) curr_stat.lr++;
      if (lr_aq_inc) curr_stat.lr_aq++;
      if (swap_aq_inc) curr_stat.swap_aq++;
      if (swap_rl_inc) curr_stat.swap_rl++;
     
      if (beq_inc) curr_stat.beq++; 
      if (bne_inc) curr_stat.bne++; 
      if (blt_inc) curr_stat.blt++; 
      if (bge_inc) curr_stat.bge++; 
      if (bltu_inc) curr_stat.bltu++; 
      if (bgeu_inc) curr_stat.bgeu++; 
      if (jalr_inc) curr_stat.jalr++; 
      if (jal_inc) curr_stat.jal++; 

      if (beq_miss_inc) curr_stat.beq_miss++; 
      if (bne_miss_inc) curr_stat.bne_miss++; 
      if (blt_miss_inc) curr_stat.blt_miss++; 
      if (bge_miss_inc) curr_stat.bge_miss++; 
      if (bltu_miss_inc) curr_stat.bltu_miss++; 
      if (bgeu_miss_inc) curr_stat.bgeu_miss++; 
      if (jalr_miss_inc) curr_stat.jalr_miss++; 
     
      if (sll_inc) curr_stat.sll++; 
      if (slli_inc) curr_stat.slli++; 
      if (srl_inc) curr_stat.srl++; 
      if (srli_inc) curr_stat.srli++; 
      if (sra_inc) curr_stat.sra++; 
      if (srai_inc) curr_stat.srai++; 

      if (add_inc) curr_stat.add++;
      if (addi_inc) curr_stat.addi++;
      if (sub_inc) curr_stat.sub++;
      if (lui_inc) curr_stat.lui++;
      if (auipc_inc) curr_stat.auipc++;
      if (xor_inc) curr_stat.xor_++;
      if (xori_inc) curr_stat.xori++;
      if (or_inc) curr_stat.or_++;
      if (ori_inc) curr_stat.ori++;
      if (and_inc) curr_stat.and_++;
      if (andi_inc) curr_stat.andi++;
      if (slt_inc) curr_stat.slt++;
      if (slti_inc) curr_stat.slti++;
      if (sltu_inc) curr_stat.sltu++;
      if (sltiu_inc) curr_stat.sltiu++;

      if (mul_inc) curr_stat.mul++;
      if (mulh_inc) curr_stat.mulh++;
      if (mulhsu_inc) curr_stat.mulhsu++;
      if (mulhu_inc) curr_stat.mulhu++;
      if (div_inc) curr_stat.div++;
      if (divu_inc) curr_stat.divu++;
      if (rem_inc) curr_stat.rem++;
      if (remu_inc) curr_stat.remu++;

      if (fence_inc) curr_stat.fence++;

      if (stall_fp_inc) curr_stat.stall_fp++;
      if (stall_depend_inc) curr_stat.stall_depend++;
      if (stall_force_wb_inc) curr_stat.stall_force_wb++;
      if (stall_ifetch_wait) curr_stat.stall_ifetch_wait++;
      if (stall_icache_store) curr_stat.stall_icache_store++;
      if (stall_lr_aq) curr_stat.stall_lr_aq++;
      if (stall_md) curr_stat.stall_md++;
      if (stall_remote_req) curr_stat.stall_remote_req++;
      if (stall_local_flw) curr_stat.stall_local_flw++;

    end
  end 


  // file logging
  //
  localparam logfile_lp = "vanilla_stats.log";

  integer fd;
  string header;

  initial begin

    #1; // we need to wait for one time unit so that my_x_i becomes a known value.

    // the first tile opens the logfile and writes the csv header.
    if ((my_x_i == x_cord_width_p'(0)) & (my_y_i == y_cord_width_p'(1))) begin
      fd = $fopen(logfile_lp, "w");
      $fwrite(fd, "x,y,tag,global_ctr,cycle,instr,");
      $fwrite(fd, "fadd,fsub,fmul,fsgnj,fsgnjn,fsgnjx,fmin,fmax,fcvt_s_w,fcvt_s_wu,fmv_w_x,");
      $fwrite(fd, "feq,flt,fle,fcvt_w_s,fcvt_wu_s,fclass,fmv_x_w,");
      $fwrite(fd, "ld,st,remote_ld,remote_st,flw,fsw,remote_flw,remote_fsw,icache_miss,");
      $fwrite(fd, "lr,lr_aq,swap_aq,swap_rl,");
      $fwrite(fd, "beq,bne,blt,bge,bltu,bgeu,jalr,jal,");
      $fwrite(fd, "beq_miss,bne_miss,blt_miss,bge_miss,bltu_miss,bgeu_miss,jalr_miss,");
      $fwrite(fd, "sll,slli,srl,srli,sra,srai,");
      $fwrite(fd, "add,addi,sub,lui,auipc,xor,xori,or,ori,and,andi,slt,slti,sltu,sltiu,");
      $fwrite(fd, "mul,mulh,mulhsu,mulhu,div,divu,rem,remu,");
      $fwrite(fd, "fence,");
      $fwrite(fd, "stall_fp,stall_depend,stall_force_wb,stall_ifetch_wait,stall_icache_store,");
      $fwrite(fd, "stall_lr_aq,stall_md,stall_remote_req,stall_local_flw");
      $fwrite(fd, "\n");
      $fclose(fd);
    end

    forever begin
      @(negedge clk_i) begin

        if (~reset_i & print_stat_v_i) begin
          $display("[BSG_INFO][VCORE_PROFILER] t=%0t x,y=%02d,%02d printing stats.",
            $time, my_x_i, my_y_i);

          fd = $fopen(logfile_lp, "a");

          $fwrite(fd, "%0d,%0d,%0d,%0d,%0d,%0d,", my_x_i, my_y_i, print_stat_tag_i, global_ctr_i, curr_stat.cycle, curr_stat.instr);

          $fwrite(fd, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,", curr_stat.fadd, curr_stat.fsub, curr_stat.fmul,
            curr_stat.fsgnj, curr_stat.fsgnjn, curr_stat.fsgnjx,
            curr_stat.fmin, curr_stat.fmax,
            curr_stat.fcvt_s_w, curr_stat.fcvt_s_wu,
            curr_stat.fmv_x_w);

          $fwrite(fd, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,", curr_stat.feq, curr_stat.flt, curr_stat.fle,
            curr_stat.fcvt_w_s, curr_stat.fcvt_wu_s,
            curr_stat.fclass, curr_stat.fmv_x_w);

          $fwrite(fd, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,",
            curr_stat.ld, curr_stat.st,
            curr_stat.remote_ld, curr_stat.remote_st,
            curr_stat.flw, curr_stat.fsw,
            curr_stat.remote_flw, curr_stat.remote_fsw,
            curr_stat.icache_miss);

          $fwrite(fd, "%0d,%0d,%0d,%0d,",
            curr_stat.lr, curr_stat.lr_aq,
            curr_stat.swap_aq, curr_stat.swap_rl);
        
          $fwrite(fd, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,",
            curr_stat.beq, curr_stat.bne, curr_stat.blt, curr_stat.bge,
            curr_stat.bltu, curr_stat.bgeu, curr_stat.jalr, curr_stat.jal);

          $fwrite(fd, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,",
            curr_stat.beq_miss, curr_stat.bne_miss, curr_stat.blt_miss, curr_stat.bge_miss,
            curr_stat.bltu_miss, curr_stat.bgeu_miss, curr_stat.jalr_miss);

          $fwrite(fd, "%0d,%0d,%0d,%0d,%0d,%0d,",
            curr_stat.sll, curr_stat.slli, curr_stat.srl, curr_stat.srli, curr_stat.sra, curr_stat.srai);

          $fwrite(fd, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,",
            curr_stat.add, curr_stat.addi, curr_stat.sub, curr_stat.lui, curr_stat.auipc,
            curr_stat.xor_, curr_stat.xori, curr_stat.or_, curr_stat.ori, 
            curr_stat.and_, curr_stat.andi, curr_stat.slt, curr_stat.slti, 
            curr_stat.sltu, curr_stat.sltiu);

          $fwrite(fd, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,",
            curr_stat.mul, curr_stat.mulh, curr_stat.mulhsu, curr_stat.mulhu,
            curr_stat.div, curr_stat.divu, curr_stat.rem, curr_stat.remu);

          $fwrite(fd, "%0d,", curr_stat.fence);
      
          $fwrite(fd, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
            curr_stat.stall_fp, curr_stat.stall_depend, curr_stat.stall_force_wb, curr_stat.stall_ifetch_wait, curr_stat.stall_icache_store,
            curr_stat.stall_lr_aq, curr_stat.stall_md, curr_stat.stall_remote_req, curr_stat.stall_local_flw);
        
      
          $fwrite(fd, "\n");

          $fclose(fd);          

        end
      end
    end
  end



endmodule
