library verilog;
use verilog.vl_types.all;
entity ddr2 is
    generic(
        tck             : integer := 5000;
        tck_min         : integer := 5000;
        tac_min         : integer := -600;
        tds             : integer := 150;
        tdh             : integer := 275;
        tdqsq           : integer := 350;
        twpre           : real    := 0.250000;
        tis             : integer := 350;
        tih             : integer := 475;
        trc             : integer := 55000;
        trcd            : integer := 15000;
        trp             : integer := 15000;
        twtr            : integer := 10000;
        txards          : integer := 6;
        cl_min          : integer := 3;
        al_min          : integer := 0;
        al_max          : integer := 5;
        cl_max          : integer := 6;
        wr_min          : integer := 2;
        wr_max          : integer := 6;
        tck_max         : integer := 8000;
        tch_min         : real    := 0.450000;
        tch_max         : real    := 0.550000;
        tcl_min         : real    := 0.450000;
        tcl_max         : real    := 0.550000;
        tdipw           : real    := 0.350000;
        tdqsh           : real    := 0.350000;
        tdqsl           : real    := 0.350000;
        tdss            : real    := 0.200000;
        tdsh            : real    := 0.200000;
        twpst_min       : real    := 0.400000;
        tdqss           : real    := 0.250000;
        tipw            : real    := 0.600000;
        tccd            : integer := 2;
        tras_min        : integer := 40000;
        tras_max        : integer := 70000000;
        trtp            : integer := 7500;
        twr             : integer := 15000;
        tmrd            : integer := 2;
        tdllk           : integer := 200;
        trfc_min        : integer := 105000;
        trfc_max        : integer := 70000000;
        txsrd           : integer := 200;
        taond           : integer := 2;
        taofd           : real    := 2.500000;
        tanpd           : integer := 3;
        taxpd           : integer := 8;
        txard           : integer := 2;
        txp             : integer := 2;
        tcke            : integer := 3;
        DM_BITS         : integer := 1;
        ADDR_BITS       : integer := 14;
        ROW_BITS        : integer := 14;
        COL_BITS        : integer := 10;
        DQ_BITS         : integer := 8;
        DQS_BITS        : integer := 1;
        trrd            : integer := 7500;
        tfaw            : integer := 37500;
        MODE_BITS       : integer := 14;
        BA_BITS         : integer := 2;
        MEM_BITS        : integer := 10;
        no_halt         : integer := 0;
        debug           : integer := 0;
        bus_delay       : integer := 0
    );
    port(
        CLK             : in     vl_logic;
        CLK_N           : in     vl_logic;
        CKE             : in     vl_logic;
        CS_N            : in     vl_logic;
        RAS_N           : in     vl_logic;
        CAS_N           : in     vl_logic;
        WE_N            : in     vl_logic;
        DM_RDQS         : inout  vl_logic_vector;
        BA              : in     vl_logic_vector;
        ADDR            : in     vl_logic_vector;
        DQ              : inout  vl_logic_vector;
        DQS             : inout  vl_logic_vector;
        DQS_N           : inout  vl_logic_vector;
        RDQS_N          : out    vl_logic_vector;
        ODT             : in     vl_logic
    );
end ddr2;
