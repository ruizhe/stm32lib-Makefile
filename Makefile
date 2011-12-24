
CROSS_COMPILE=arm-none-eabi-
CC=$(CROSS_COMPILE)gcc
AR=$(CROSS_COMPILE)ar
AS=$(CROSS_COMPILE)as

CFLAGS=-c -g -mcpu=cortex-m3 -mthumb -DSTM32F10X_MD
ASFLAGS=-c -g -mcpu=cortex-m3 -mthumb

OUTDIR=./_stage

DIRS=Libraries/CMSIS/CM3/CoreSupport \
	 Libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x \
	 Libraries/STM32F10x_StdPeriph_Driver/inc \
	 Libraries/STM32F10x_StdPeriph_Driver/src

STARTUP_DIR=Libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x/startup/gcc_ride7
STARTUP_SRC=$(wildcard $(STARTUP_DIR)/*.s)
STARTUP_OBJ=$(foreach SRC, $(STARTUP_SRC), $(OUTDIR)/lib/$(notdir $(SRC:.s=.o)))

INCDIRS=$(foreach DIR, $(DIRS), -I$(DIR))
SRCS=$(foreach DIR, $(DIRS), $(wildcard $(DIR)/*.c))
INCS=$(foreach DIR, $(DIRS), $(wildcard $(DIR)/*.h))

DSTINCS=$(foreach INC, $(INCS), $(OUTDIR)/inc/$(notdir $(INC)))
DSTOBJS=$(SRCS:.c=.o)

DSTLIB=$(OUTDIR)/lib/stm32lib.a

STARTUP_DEP=$(foreach SRC, $(STARTUP_SRC), \
			"\n$(OUTDIR)/lib/$(notdir $(SRC:.s=.o)):$(SRC)\n\t\$$(AS) \$$(ASFLAGS) -o \$$@ \$$<")
INCDEP=$(foreach INC, $(INCS), \
		"\n$(OUTDIR)/inc/$(notdir $(INC)):$(INC)\n\tcp -f \$$< \$$@")

all:$(OUTDIR)/lib \
	$(OUTDIR)/inc \
	deps.d \
	$(DSTINCS) \
	$(DSTLIB) \
	$(STARTUP_OBJ) \
	$(OUTDIR)/Makefile.inc

$(OUTDIR)/lib $(OUTDIR)/inc:
	mkdir -p $@

$(DSTLIB):$(DSTOBJS)
	$(AR) crs $@ $^

$(OUTDIR)/Makefile.inc:Makefile.inc
	cp -f $< $@

include deps.d

deps.d:$(SRCS) $(INCS)
	rm -rf $@
	touch $@
	echo -e $(INCDEP) >> $@
	echo -e $(STARTUP_DEP) >> $@

OBJS=$(SRCS:.c=.o)

%.o:%.c
	$(CC) $(CFLAGS) $(INCDIRS) -o $@ $<

clean:
	rm -rf _stage
	rm -rf deps.d
	rm -rf $(DSTOBJS)
