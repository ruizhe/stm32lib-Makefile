STM32LIB_DIR=../z1.st.fwlib/STM32F10x_StdPeriph_Lib_V3.5.0
OUTDIR=../z1.st.fwlib/output

CROSS_COMPILE=arm-none-eabi-
CC=$(CROSS_COMPILE)gcc
AR=$(CROSS_COMPILE)ar
AS=$(CROSS_COMPILE)as

CFLAGS=-c -mcpu=cortex-m3 -mthumb -nostartfiles -DSTM32F10X_MD \
	   -DUSE_STDPERIPH_DRIVER -I$(OUTDIR)/inc

ASFLAGS=-mcpu=cortex-m3 -mthumb


DIRS=$(addprefix $(STM32LIB_DIR)/, Libraries/CMSIS/CM3/CoreSupport \
	 Libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x \
	 Libraries/STM32F10x_StdPeriph_Driver/inc \
	 Libraries/STM32F10x_StdPeriph_Driver/src)

STARTUP_DIR=$(STM32LIB_DIR)/Libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x/startup/gcc_ride7
STARTUP_SRC=$(wildcard $(STARTUP_DIR)/*.s)
STARTUP_OBJ=$(foreach SRC, $(STARTUP_SRC), $(OUTDIR)/lib/$(notdir $(SRC:.s=.o)))

INCDIRS=$(foreach DIR, $(DIRS), -I$(DIR))
SRCS=$(foreach DIR, $(DIRS), $(wildcard $(DIR)/*.c))
INCS=$(foreach DIR, $(DIRS), $(wildcard $(DIR)/*.h))

DSTINCS=$(foreach INC, $(INCS), $(OUTDIR)/inc/$(notdir $(INC)))
DSTOBJS=$(SRCS:.c=.o)

DSTLIB=$(OUTDIR)/lib/libstm32.a

STARTUP_DEP=$(foreach SRC, $(STARTUP_SRC), \
			"\n$(OUTDIR)/lib/$(notdir $(SRC:.s=.o)):$(SRC)\n\t\$$(AS) \$$(ASFLAGS) -o \$$@ \$$<")

default:all

define mkdeps
$(foreach INC, $(INCS),
$(OUTDIR)/inc/$(notdir $(INC)):$(INC)
	cp -f $$< $$@
)
endef

$(eval $(call mkdeps))

all:$(OUTDIR)/lib \
	$(OUTDIR)/inc \
	$(OUTDIR)/Makefile.inc \
	$(OUTDIR)/Makefile.template \
	$(OUTDIR)/template.ld \
	$(OUTDIR)/inc/stm32f10x_conf.h \
	$(DSTINCS) \
	$(DSTLIB) \
	$(STARTUP_OBJ) \

$(OUTDIR)/lib $(OUTDIR)/inc:
	mkdir -p $@

$(DSTLIB):$(DSTOBJS)
	$(AR) cr $@ $^

$(OUTDIR)/Makefile.inc:Makefile.inc
	cp -f $< $@

$(OUTDIR)/Makefile.template:Makefile.template
	cp -f $< $@

$(OUTDIR)/template.ld:template.ld
	cp -f $< $@

$(OUTDIR)/inc/stm32f10x_conf.h:$(STM32LIB_DIR)/Project/STM32F10x_StdPeriph_Template/stm32f10x_conf.h
	cp -f $< $@

OBJS=$(SRCS:.c=.o)

%.o:%.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -rf $(OUTDIR)
	rm -rf $(DSTOBJS)
