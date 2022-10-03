#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"

typedef
	 struct {
	unsigned int Date;
	unsigned int Reserved;
	unsigned int testreg_A;
	unsigned int testreg_B;
} T_TEST;

typedef
	 struct {
	unsigned int Date;				// 0
	unsigned int Reserved;
	unsigned int testreg_A;
	unsigned int testreg_B;
	unsigned int START_GP_RD;			// 4
	unsigned int STATE_GP_RD;
	unsigned int ADDR_AXI_GP_RD;
	unsigned int bursts_gp_rd;
	unsigned int packets_gp_rd;		// 8
	unsigned int timer_stop_gp;
	unsigned int timer_stop_hp;
	unsigned int START_HP;
	unsigned int STATE_HP;			// 12
	unsigned int ADDR_AXI_HP;
	unsigned int bursts_hp;
	unsigned int packets_hp;
	unsigned int START_GP_WR;			// 4
	unsigned int STATE_GP_WR;
	unsigned int ADDR_AXI_GP_WR;
	unsigned int bursts_gp_wr;
	unsigned int packets_gp_wr;		// 8
	unsigned int LEN;
	unsigned int BURST;
	unsigned int SIZE_GP;



} T_AXI;

volatile       			T_TEST *TEST_SB;
volatile       			T_AXI *AXI_SB;

unsigned int ARR[2000000];
unsigned int ARR2[2000000];
unsigned int *ARR_L, ARR_LL;
unsigned int *ARR2_L, ARR2_LL;
int i;

int main()
{
    init_platform();

	AXI_SB = (T_AXI *)((unsigned int*) XPAR_AXI4LITE_2_TMS_0_BASEADDR + 2097152*0);

	TEST_SB = (T_TEST *)((unsigned int*) XPAR_AXI4LITE_2_TMS_0_BASEADDR + 2097152*1);

    print("Hello World\n\r");

    for (i=0;i<2000000;i++)
		{
    		ARR[i] = i*4;//+0x010802b;
    		ARR2[i] = i*4;//+0x010802b;
		}
    for (i=0;i<2000000;i++)
		{
    		ARR[i] = ARR[i]+1;
    		ARR2[i] = ARR2[i]+1;
		}
    for (i=0;i<2000000;i++)
		{
    		ARR[i] = ARR[i]-1;
    		ARR2[i] = ARR2[i]-1;
		}
//    ARR[0] = 0x5555AAAA;
//    ARR[1] = 0x11112222;
//    ARR[2] = 0x33334444;
//    ARR[3] = 0x55556666;

    ARR_L = ARR;
    ARR_LL = ARR_L;
    ARR_LL = ((ARR_LL/4096)+1)*4096;
    ARR_L = ARR_LL;
    ARR2_L = ARR2;
    ARR2_LL = ARR2_L;
    ARR2_LL = ((ARR2_LL/4096)+1)*4096;
    ARR2_L = ARR2_LL;
    AXI_SB->ADDR_AXI_GP_WR = ARR_L;
    AXI_SB->START_GP_WR = 1;

    i = ARR[0];

    cleanup_platform();
    return 0;
}
