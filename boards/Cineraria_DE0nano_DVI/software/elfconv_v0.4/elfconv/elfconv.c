#include<stdio.h>
#include<stdlib.h>

#include "elf32.h"

void eh_endian_conv(ELF32_HEADER *);
void ph_endian_conv(ELF32_PHEADER *);
void print_elfinfo(FILE *);
int conv_bitrevers(int,int);
void write_intdata(FILE *,unsigned long,int,int);
int conv_sectiondata(FILE *,FILE *,int,int,int,int);
int conv_elfdata(FILE *,FILE *,FILE *,int,int);
void conv_userdata(FILE *,FILE *,int);
void conv_srecdata(FILE *,FILE *,unsigned long);
void conv_hexdata(FILE *,FILE *,unsigned long);


int main(int argc,char *argv[])
{
	int i;
	int flag_rev=0,flag_comp=0,flag_info=0,flag_srec=0,flag_hex=0,flag_user=0;
	char *fname="out.bin",*sname,*hname,*uname="- none -";
	unsigned long offs=0;
	FILE *felf=NULL,*fout=NULL,*fbin=NULL,*ftxt=NULL;

	printf("\n<elfconv v0.2>  elf-file converter & archiver\n");
	printf("           (C)S.OSAFUNE,(C)2007-2009 J-7SYSTEM WORKS. ALL RIGHTS RESERVED.\n\n");

	if(argc < 2){
		printf("Usage : elfconv ����elf�t�@�C���� [-v | [-o][-u][-r][-c][-s | -h][-l]]\n");
//		printf("     -v  : elf�t�@�C���̏ڍׂȃf�[�^��\�����܂�.\n");
		printf("     -v  : elf�t�@�C���̏ڍׂȃf�[�^��\x95\\�����܂�.\n");
		printf("     -r  : �o�͂���f�[�^�o�C�g�̃r�b�g���т��t���ɂ��܂�.\n");
		printf("     -c  : �Z�N�V�����f�[�^�����k���܂�.\n");
		printf("     -o <filename> : �o�̓t�@�C�������w�肵�܂�.\n");
		printf("     -u <filename> : �ǉ�����f�[�^�t�@�C�������w�肵�܂�.\n");
		printf("     -s <filename> : srec�`���̃f�[�^�������o���܂�.\n");
		printf("     -h <filename> : ihex�`���̃f�[�^�������o���܂�.\n");
		printf("     -l <offset>   : srec,ihex�̃I�t�Z�b�g��16�i���Ŏw�肵�܂�.\n");

		exit(0);
	}

	/* elf�t�@�C���̃I�[�v�� */
	if((felf = fopen(*(argv+1),"rb")) == NULL){
		printf("[�I]���̓t�@�C�� %s ���J���܂���.\n",*(argv+1));
		exit(-1);
	}
	printf("Input elf-file: %s\n",*(argv+1));

	/* �I�v�V�����p�����[�^�̐ݒ� */
	i = 2;
	while(i<argc) {
		if( strcmp(*(argv+i),"-v")==0 || strcmp(*(argv+i),"-V")==0 ){
			flag_info = 1;
		} else if( strcmp(*(argv+i),"-r")==0 || strcmp(*(argv+i),"-R")==0 ){
			flag_rev = 1;
		} else if( strcmp(*(argv+i),"-c")==0 || strcmp(*(argv+i),"-C")==0 ){
			flag_comp = 1;
		} else if( strcmp(*(argv+i),"-o")==0 || strcmp(*(argv+i),"-O")==0 ){
			i++;
			fname = *(argv+i);
		} else if( strcmp(*(argv+i),"-u")==0 || strcmp(*(argv+i),"-U")==0 ){
			i++;
			uname = *(argv+i);
			flag_user = 1;
		} else if( strcmp(*(argv+i),"-s")==0 || strcmp(*(argv+i),"-S")==0 ){
			i++;
			sname = *(argv+i);
			flag_srec = 1;
		} else if( strcmp(*(argv+i),"-h")==0 || strcmp(*(argv+i),"-H")==0 ){
			i++;
			hname = *(argv+i);
			flag_hex = 1;
		} else if( strcmp(*(argv+i),"-l")==0 || strcmp(*(argv+i),"-L")==0 ){
			i++;
			offs = strtol(*(argv+i),(char **)NULL,16);
		}
		i++;
	}

	/* �ڍׂȏ���\�� */
	if(flag_info != 0) {
		print_elfinfo(felf);
		fclose(felf);
		exit(0);
	}

	/* �ϊ��J�n */
	printf("Payload file  : %s\n",uname);
	if(flag_user != 0) {
		if((fbin = fopen(uname,"rb")) == NULL){
			printf("[�I]���̓t�@�C�� %s ���J���܂���.\n",uname);
			exit(-1);
		}
	}
	printf("Output file   : %s\n",fname);
	if((fout = fopen(fname,"wb")) == NULL){
		printf("[�I]�o�̓t�@�C�� %s ���J���܂���.\n",fname);
		exit(-1);
	}
	if(conv_elfdata(felf,fbin,fout,flag_rev,flag_comp) != 0) {
		exit(-1);
	}
	fclose(fout);
	fclose(fbin);
	fclose(felf);
	printf("\n");

	/* srec�`���̃t�@�C�����쐬 */
	if(flag_srec != 0) {
		if((ftxt = fopen(sname,"w")) == NULL){
			printf("[�I]�o�̓t�@�C�� %s ���J���܂���.\n",sname);
			exit(-1);
		}
		fout = fopen(fname,"rb");
		printf("<convert to S-Record> %s -> %s\n",fname,sname);
		conv_srecdata(fout,ftxt,offs);
		fclose(fout);
		fclose(ftxt);
	}

	/* hex�`���̃t�@�C�����쐬 */
	if(flag_hex != 0) {
		if((ftxt = fopen(hname,"w")) == NULL){
			printf("[�I]�o�̓t�@�C�� %s ���J���܂���.\n",hname);
			exit(-1);
		}
		fout = fopen(fname,"rb");
		printf("<convert to IntelHEX> %s -> %s\n",fname,hname);
		conv_hexdata(fout,ftxt,offs);
		fclose(fout);
		fclose(ftxt);
	}

	printf("\n");
	exit(0);
}




/***** �w�b�_�t�@�C���G���f�B�A���ϊ� **********/
ELF32_Half endian_conv_half(ELF32_Half a)
{
	char tmp,*p;

	p = (char *)&a;
	tmp = *p;
	*p = *(p+1);
	*(p+1) = tmp;

	return(a);
}

ELF32_Word endian_conv_word(ELF32_Word a)
{
	char tmp,*p;

	p = (char *)&a;
	tmp = *p;
	*p = *(p+3);
	*(p+3) = tmp;
	tmp = *(p+1);
	*(p+1) = *(p+2);
	*(p+2) = tmp;

	return(a);
}

void eh_endian_conv(ELF32_HEADER *eh)		// elf�t�@�C���w�b�_�̃G���f�B�A���ϊ� 
{
	eh->elf_type     = endian_conv_half(eh->elf_type);
	eh->elf_machine  = endian_conv_half(eh->elf_machine);
	eh->elf_version  = endian_conv_word(eh->elf_version);
	eh->elf_entry    = (ELF32_Addr)endian_conv_word((ELF32_Word)eh->elf_entry);
	eh->elf_phoff    = (ELF32_Off)endian_conv_word((ELF32_Off)eh->elf_phoff);
	eh->elf_shoff    = (ELF32_Off)endian_conv_word((ELF32_Off)eh->elf_shoff);
	eh->elf_flags    = endian_conv_word(eh->elf_flags);
	eh->elf_ehsize   = endian_conv_half(eh->elf_ehsize);
	eh->elf_phentsize= endian_conv_half(eh->elf_phentsize);
	eh->elf_phnum    = endian_conv_half(eh->elf_phnum);
	eh->elf_shentsize= endian_conv_half(eh->elf_shentsize);
	eh->elf_shnum    = endian_conv_half(eh->elf_shnum);
	eh->elf_shstrndx = endian_conv_half(eh->elf_shstrndx);
}

void ph_endian_conv(ELF32_PHEADER *ph)		// Program�w�b�_�e�[�u���̃G���f�B�A���ϊ� 
{
	ph->p_type   = endian_conv_word(ph->p_type);
	ph->p_offset = (ELF32_Off)endian_conv_word((ELF32_Off)ph->p_offset);
	ph->p_vaddr  = (ELF32_Addr)endian_conv_word((ELF32_Word)ph->p_vaddr);
	ph->p_paddr  = (ELF32_Addr)endian_conv_word((ELF32_Word)ph->p_paddr);
	ph->p_filesz = endian_conv_word(ph->p_filesz);
	ph->p_memsz  = endian_conv_word(ph->p_memsz);
	ph->p_flags  = endian_conv_word(ph->p_flags);
	ph->p_align  = endian_conv_word(ph->p_align);
}


/***** elf�t�@�C����� **********/
void print_elfinfo(FILE *felf)
{
	int i,phnum;
	char *p,*s;
	ELF32_HEADER eh;
	ELF32_PHEADER ph;

	if(felf == NULL) return;

	/* elf�w�b�_�t�@�C����ǂݍ��� */
	fseek(felf,0,SEEK_SET);
	p = (char *)&eh;
	for(i=0 ; i<sizeof(ELF32_HEADER) ; i++,p++)
		*p = (char)fgetc(felf);
	if(eh.elf_id[5] == 0x02) eh_endian_conv(&eh);

	if(eh.elf_id[0] == 0x7f &&				// ELF�w�b�_�̃`�F�b�N 
			eh.elf_id[1] == 'E' &&
			eh.elf_id[2] == 'L' &&
			eh.elf_id[3] == 'F') {

		printf("\n-< Elf file infomation >---\n");
		printf("Elf header magic   : 0x%02x 0x%02x 0x%02x 0x%02x\n",
					eh.elf_id[0],eh.elf_id[1],eh.elf_id[2],eh.elf_id[3]);
		printf("Elf header version : 0x%02x\n",eh.elf_id[6]);
		printf("Elf header size    : %d bytes\n",eh.elf_ehsize);
		printf("Elf file version   : 0x%08x\n",eh.elf_version);

		printf("Elf object type    : ");		// �I�u�W�F�N�g�^�C�v 
		switch(eh.elf_type) {
		case ELF_ET_REL:
			printf("relocatable\n");
			break;
		case ELF_ET_EXEC:
			printf("executable\n");
			break;
		case ELF_ET_DYN:
			printf("dynamic\n");
			break;
		case ELF_ET_CORE:
			printf("core module\n");
			break;
		default:
			printf("unknow type\n");
			break;
		}

		printf("Elf target OS/ABI  : 0x%02x\n",eh.elf_id[7]);
		printf("Elf ABI version    : 0x%02x\n",eh.elf_id[8]);

		printf("Elf target cpu     : ");		// �^�[�Q�b�g�A�[�L�e�N�`�� 
		switch(eh.elf_machine) {
		case ELF_EM_NONE:
			printf("None target processor\n");
			break;

		case ELF_EM_SPARC:
			printf("SPARC processor\n");
			break;
		case ELF_EM_SPARC32P:
			printf("Enhanced instruction set SPARC\n");
			break;
		case ELF_EM_SPARCV9:
			printf("SPARC Version 9\n");
			break;
		case ELF_EM_386:
			printf("Intel 80386\n");
			break;
		case ELF_EM_860:
			printf("Intel 80860\n");
			break;
		case ELF_EM_960:
			printf("Intel 80960\n");
			break;
		case ELF_EM_68K:
			printf("Motorola 68000\n");
			break;
		case ELF_EM_68HC05:
			printf("Motorola 68HC05\n");
			break;
		case ELF_EM_68HC08:
			printf("Motorola 68HC08\n");
			break;
		case ELF_EM_68HC11:
			printf("Motorola 68HC11\n");
			break;
		case ELF_EM_68HC12:
			printf("Motorola 68HC12\n");
			break;
		case ELF_EM_68HC16:
			printf("Motorola 68HC16\n");
			break;
		case ELF_EM_COLDFIRE:
			printf("Motorola ColdFire\n");
			break;
		case ELF_EM_PPC:
			printf("IBM PowerPC\n");
			break;
		case ELF_EM_ARM:
			printf("ARM processor\n");
			break;
		case ELF_EM_MIPS:
			printf("MIPS-I processor\n");
			break;
		case ELF_EM_RS3_LE:
			printf("MIPS RS3000(Little-endian)\n");
			break;
		case ELF_EM_MIPS_X:
			printf("Stanford MIPS-X\n");
			break;
		case ELF_EM_SH:
			printf("Renesas SH\n");
			break;
		case ELF_EM_H8_300:
			printf("Renesas H8/300\n");
			break;
		case ELF_EM_H8_300H:
			printf("Renesas H8/300H\n");
			break;
		case ELF_EM_H8S:
			printf("Renesas H8S\n");
			break;
		case ELF_EM_H8_500:
			printf("Renesas H8/500\n");
			break;
		case ELF_EM_NIOS:
			printf("Altera Nios processor\n");
			break;
		case ELF_EM_NIOS2:
			printf("Altera NiosII processor\n");
			break;
		case ELF_EM_MBLAZE:
			printf("Xilinx MicroBlaze processor\n");
			break;

		default:
			printf("unknow machine(0x%04x)\n",eh.elf_machine);
			break;
		}

		printf("Elf object class   : ");		// �I�u�W�F�N�g�N���X 
		if(eh.elf_id[4] == 0x01) {
			printf("32bit\n");
		} else if(eh.elf_id[4] == 0x02) {
			printf("64bit\n");
		} else {
			printf("invalid\n");
		}

		printf("Elf endian type    : ");		// �I�u�W�F�N�g�̃G���f�B�A�� 
		if(eh.elf_id[5] == 0x01) {
			printf("Little (LSB first, 2's complement)\n");
		} else if(eh.elf_id[5] == 0x02) {
			printf("Big (MSB first, 2's complement)\n");
		} else {
			printf("invalid\n");
		}

		printf("Elf processor flags: 0x%08x\n",eh.elf_flags);
		printf("Elf entry address  : 0x%08x\n",(unsigned long)eh.elf_entry);

		printf("\n");
		printf("Program header-table size : %d bytes/table\n",eh.elf_phentsize);
		printf("Program header-table num  : %d\n",eh.elf_phnum);

	/* Program�w�b�_�e�[�u����ǂݍ��� */
		fseek(felf, eh.elf_ehsize ,SEEK_SET);

		for(phnum=1 ; phnum<=eh.elf_phnum ; phnum++) {
			printf("- Section %d -----\n",phnum);

			p = (char *)&ph;
			for(i=0 ; i<eh.elf_phentsize ; i++,p++)
				*p = (char)fgetc(felf);
			if(eh.elf_id[5] == 0x02) ph_endian_conv(&ph);

			printf("Segment entry type : ");
			switch(ph.p_type) {
			case ELF_PT_NULL:
				printf("not use entry\n");
				break;
			case ELF_PT_LOAD:
				printf("load-execution\n");
				break;
			case ELF_PT_DYNAMIC:
				printf("dynamic-struct\n");
				break;
			case ELF_PT_INTERP:
				printf("interpreter\n");
				break;
			case ELF_PT_NOTE:
				printf("note\n");
				break;
			case ELF_PT_PHDR:
				printf("program header table\n");
				break;
			default:
				printf("reserved\n");
				break;
			}

			printf("  File data offset : 0x%08x\n",ph.p_offset);
			printf("  File data size   : %d bytes\n",ph.p_filesz);
			printf("  Memory area size : %d bytes\n",ph.p_memsz);
			printf("  Memory address   : 0x%08x\n",(unsigned long)ph.p_vaddr);
			printf("  Physical address : 0x%08x\n",(unsigned long)ph.p_paddr);

			printf("  Segment flags    :");
			if((ph.p_flags & ELF_PF_R)!= 0) printf(" read");
			if((ph.p_flags & ELF_PF_W)!= 0) printf(" write");
			if((ph.p_flags & ELF_PF_X)!= 0) printf(" execute");
			if(ph.p_flags == 0) printf(" none");
			printf("\n");

			printf("  Data alignment   : 0x%08x\n",ph.p_align);
		}
		printf("-----------------\n");

	} else {
		printf("[!] elf�t�@�C�����w�肵�Ă�������.\n");
	}

	printf("\n");
}


/***** �r�b�g�������ւ� **********/
int conv_bitrevers(int j,int f)
{
	int c=0;

	if(f != 0) {
		if ( (j & 0x01)!= 0 ) c |= 0x80;
		if ( (j & 0x02)!= 0 ) c |= 0x40;
		if ( (j & 0x04)!= 0 ) c |= 0x20;
		if ( (j & 0x08)!= 0 ) c |= 0x10;
		if ( (j & 0x10)!= 0 ) c |= 0x08;
		if ( (j & 0x20)!= 0 ) c |= 0x04;
		if ( (j & 0x40)!= 0 ) c |= 0x02;
		if ( (j & 0x80)!= 0 ) c |= 0x01;
	} else {
		c = j;
	}

	return(c);
}


/***** 32bit�f�[�^���t�@�C���ɏ������� **********/
void write_intdata(FILE *fout,unsigned long data,int endian,int flag_rev)
{
	int i,c;

	for(i=0 ; i<4 ; i++) {
		if(endian == 0) {
			c = conv_bitrevers(data & 0xff, flag_rev);
			data >>= 8;
		} else {
			c = conv_bitrevers((data & 0xff000000)>>24, flag_rev);
			data <<= 8;
		}
		fputc(c, fout);
	}
}


/***** �o�C�i���X�g���[����LZSS���k���� **********/
#define nd_LZSS_refaddrbit		(12)
#define nd_LZSS_copylengthbit	(4)
#define nd_LZSS_refaddrshift	nd_LZSS_copylengthbit
#define nd_LZSS_clbitmask		(0x0f)
#define nd_LZSS_windowsize		(4095)
#define nd_LZSS_maxlength		(nd_LZSS_clbitmask + 2)

#define nd_LZSS_ctrlLITERAL		(0)
#define nd_LZSS_ctrlCODEWORD	(1)
#define nd_LZSS_ctrlbitmask		(0x80)


int nd_LZSSdecompress(
		unsigned char *pSrc,		// ���k�f�[�^�o�C�g�� 
		unsigned char *pDst,		// �f�[�^�̓W�J��ւ̃|�C���^ 
		int bytesize)				// �W�J��̃o�C�g�T�C�Y 
{
	unsigned char *pTop,*pEnd;
	int i=0,j,ctrl,refaddr,copylen;

	pTop = pDst;
	pEnd = pTop + bytesize;
	while(pDst < pEnd) {
		if(i == 0) {				// �R���g���[���o�C�g 
			ctrl = *(pSrc++);
			i = 7;
		} else {
			ctrl <<= 1;
			i--;
		}

		if( (ctrl & nd_LZSS_ctrlbitmask)== 0 ) {	// ���f�[�^ 
			*pDst++ = *pSrc++;

		} else {									// �Q�ƃf�[�^ 
			j  = *pSrc++;
			j  = (j << 8) | *pSrc++;
			if (j == 0) break;						// �f�[�^�p�P�b�g��0�̏ꍇ��EOF 

			refaddr = j >> nd_LZSS_refaddrshift;	// �Q�ƃA�h���X��(12bit) 
			copylen =(j & nd_LZSS_clbitmask) + 2;	// �R�s�[��(4bit) 

			for(j=0 ; (j<copylen)&&(pDst<pEnd) ; j++,pDst++)
				*pDst = *(pDst - refaddr);
		}
	}

	return((int)(pDst - pTop));
}

unsigned char *nd_LZSScompScanStr(
		unsigned char *pStr,
		unsigned char *pSrc,
		int maxlength,
		int *bestlength)
{
	int i;
	unsigned char *p,*pBest,*pStr1,*pStr2;

	*bestlength = 1;
	pBest = (unsigned char *)NULL;
	p = (pStr - 1);

	//�X���C�h���̏�����牺���̊ԂŁA�����Ƃ������}�b�`���O�o�C�g���������� 
	while(p >= pSrc) {
		if (*p == *pStr) {
			pStr1 = (p + 1);
			pStr2 = (pStr + 1);
			for(i=1 ; (i < maxlength)&&(pStr1 < pStr) ; i++)
				if (*pStr1++ != *pStr2++) break;

			if (i > *bestlength) {
				*bestlength = i;
				pBest = p;
			}
		}
		p--;
	}
	return(pBest);
}

int conv_sectiondata(
		FILE *felf,FILE *fout,
		int bytesize,
		int endian,int flag_rev,int flag_comp)
{
	int i,c,compsize,lmax,lref,llazy,rindex,cbyte=0,ccount=0,k=0,rval;
	unsigned char *p,*pCtrl,*pTemp,*pRef,*pLazy,*pVrf_top;
	unsigned char *pSrc,*pSrc_top,*pSrc_end;
	unsigned char *pDst,*pDst_top,*pDst_end;

	pSrc_top = malloc(bytesize);
	pDst_top = malloc(bytesize);
	pVrf_top = malloc(bytesize);

	for(i=0 ; i<bytesize ; i++) *(pSrc_top+i) = fgetc(felf);

	pSrc = pSrc_top;
	pDst = pDst_top;
	pSrc_end = (pSrc + bytesize);
	pDst_end = (pDst + bytesize);
	pRef = (unsigned char *)NULL;
	p = pSrc;
	pCtrl = pDst++;

	printf("  Data compress ");

	while((p < pSrc_end)&&(flag_comp!=0)) {
		ccount++;
		if (ccount == 9) {							// �R���g���[���o�C�g�̏������� 
			*pCtrl = cbyte;
			pCtrl  = pDst++;
			cbyte  = 0;
			ccount = 1;
		}

		lmax = (int)(pSrc_end - p);
		if (lmax > nd_LZSS_maxlength) lmax = nd_LZSS_maxlength;

		pTemp = (p - nd_LZSS_windowsize);
		if (pTemp < pSrc) pTemp = pSrc;

		if (pRef ==(unsigned char *)NULL)			// ��v�o�C�g�񌟍� 
			pRef = nd_LZSScompScanStr(p, pTemp, lmax, &lref);
		if (lmax > 1)								// ���̈�v�o�C�g������ 
			pLazy = nd_LZSScompScanStr(p+1, pTemp+1, lmax--, &llazy);
					// ���̈�v�o�C�g�̕������ʂ��ǂ��Ȃ�A����̌��ʂ͔j������ 

													// ���f�[�^�p�P�b�g�̏������� 
		if( ((pLazy !=(unsigned char *)NULL)&&(llazy > lref))||
			 (pRef ==(unsigned char *)NULL)||(lmax == 0) ) {
			pRef = pLazy;
			lref = llazy;
			cbyte <<= 1;
			cbyte |= nd_LZSS_ctrlLITERAL;
			*pDst++ = *p++;
			k++;
		} else {									// �Q�ƃf�[�^�p�P�b�g�̏������� 
			cbyte <<= 1;
			cbyte |= nd_LZSS_ctrlCODEWORD;
			rindex = (int)(p - pRef);
			rindex = (rindex << nd_LZSS_refaddrshift) | ((lref - 2)& nd_LZSS_clbitmask);
			*pDst++ = (unsigned char)((rindex >> 8)& 0xff);
			*pDst++ = (unsigned char)(rindex & 0xff);
			p += lref;
			k += lref;
			pRef = (unsigned char *)NULL;
		}

		if (pDst >= pDst_end) flag_comp = 0;		// ���k�Ɏ��s���� 

		if( (k*25) > bytesize) {
			k = 0;
			printf(".");
		}
	}

	if (flag_comp == 0) {				// �񈳏k�ŃZ�N�V�����f�[�^���i�[ 
		for(i=0 ; i<bytesize ; i++) {
			c = conv_bitrevers(*(pSrc_top+i), flag_rev);
			fputc(c, fout);
		}
		printf("skip\n");

		rval = -1;

	} else {							// ���k�����Z�N�V�����f�[�^���i�[ 
		ccount++;						// EOF�p�P�b�g�̏������� 
		cbyte <<= 1;
		cbyte |= nd_LZSS_ctrlCODEWORD;
		*pDst++ = 0;
		*pDst++ = 0;
		while(ccount != 8) {
			cbyte <<= 1;
			ccount++;
		}
		*pCtrl = cbyte;

										// �W�J�C���[�W�T�C�Y�̏������� 
		write_intdata(fout, bytesize, endian, flag_rev);
										// ���k�o�C�i���f�[�^�̏������� 
		compsize = (int)(pDst - pDst_top);
		for(i=0 ; i<compsize ; i++) {
			c = conv_bitrevers(*(pDst_top+i), flag_rev);
			fputc(c, fout);
		}
		compsize += 4;

		printf("(%d",(int)(p - pSrc_top));
		i = nd_LZSSdecompress(pDst_top, pVrf_top, bytesize);
		printf(",%d",i);
		for(i-- ; i>0 ; i--)
			if (*(pSrc_top + i) != *(pVrf_top + i)) {
				printf(",[!]verify error");
				break;
			}
		printf(")");


		printf("done\n",compsize*100/bytesize);
		printf("  Compressed  : %d (0x%08x) bytes / %d%%\n",compsize,compsize,compsize*100/bytesize);

		rval = compsize;
	}

	free(pVrf_top);
	free(pDst_top);
	free(pSrc_top);

	return(rval);
}


/***** elf���s�`������Z�N�V�����A�[�J�C�u�o�C�i�����쐬 **********/
int conv_elfdata(FILE *felf,FILE *fbin,FILE *fout,int flag_rev,int flag_comp)
{
	int i,c,phnum,endian;
	unsigned long tmp;
	char *p,*s;
	fpos_t fpos,ftop,ftmp;
	ELF32_HEADER eh;
	ELF32_PHEADER ph;

	/* elf�w�b�_�t�@�C���̃`�F�b�N */
	fseek(felf,0,SEEK_SET);
	p = (char *)&eh;
	for(i=0 ; i<sizeof(ELF32_HEADER) ; i++,p++)
		*p = (char)fgetc(felf);
	if(eh.elf_id[5] == 0x02) eh_endian_conv(&eh);

	if(eh.elf_id[0] != 0x7f ||				// ELF�w�b�_�̃`�F�b�N 
			eh.elf_id[1] != 'E' ||
			eh.elf_id[2] != 'L' |
			eh.elf_id[3] != 'F') {
		printf("[!] elf�t�@�C�����w�肵�Ă�������.\n\n");
		return(-1);
	}

	if(eh.elf_type != ELF_ET_EXEC) {	// �I�u�W�F�N�g�^�C�v�̃`�F�b�N 
		printf("[!] ���s�`����elf�t�@�C�����w�肵�Ă�������.\n\n");
		return(-1);
	}

	switch(eh.elf_machine) {			// �^�[�Q�b�gCPU�̃`�F�b�N 
	case ELF_EM_68K:
		s = "Motorola 68000";
		break;
	case ELF_EM_PPC:
		s = "IBM PowerPC";
		break;
	case ELF_EM_ARM:
		s = "ARM processor";
		break;
	case ELF_EM_MIPS:
		s = "MIPS-I processor";
		break;
	case ELF_EM_RS3_LE:
		s = "MIPS RS3000(Little-endian)";
		break;
	case ELF_EM_SH:
		s = "Renesas SH";
		break;
	case ELF_EM_NIOS:
		s = "Altera Nios processor";
		break;
	case ELF_EM_NIOS2:
		s = "Altera NiosII processor";
		break;
	case ELF_EM_MBLAZE:
		s = "Xilinx MicroBlaze processor";
		break;

	default:
		printf("[!] �Ή����Ă��Ȃ�CPU�ł�.\n\n");
		return(-1);
	}
	printf("\nTarget CPU    : %s\n",s);

	if(eh.elf_id[5] == 0x01) {			// �I�u�W�F�N�g�̃G���f�B�A�� 
		s = "Little";
		endian = 0;
	} else if(eh.elf_id[5] == 0x02) {
		s = "Big";
		endian = 1;
	} else {
		s = "invalid";
		endian = 0;
	}
	printf("Endian type   : %s\n",s);
	printf("Entry address : 0x%08x\n",(unsigned long)eh.elf_entry);


	/* �t�@�C���w�b�_�𐶐� */
	fgetpos(fout, &ftop);
	fputc(conv_bitrevers('P',flag_rev), fout);
	fputc(conv_bitrevers('R',flag_rev), fout);
	fputc(conv_bitrevers('O',flag_rev), fout);
	fputc(conv_bitrevers('C',flag_rev), fout);
	for(i=0 ; i<4 ; i++) fputc(0, fout);


	/* �o�C�i���f�[�^�𐶐� */
	fseek(felf, eh.elf_ehsize ,SEEK_SET);
	for(phnum=1 ; phnum<=eh.elf_phnum ; phnum++) {

		// Program�w�b�_��ǂݍ��� 
		p = (char *)&ph;
		for(i=0 ; i<eh.elf_phentsize ; i++,p++)
			*p = (char)fgetc(felf);
		if(eh.elf_id[5] == 0x02) ph_endian_conv(&ph);

		// �Z�N�V�����f�[�^���o�C�i���t�@�C���ɓW�J 
		if(ph.p_type == ELF_PT_LOAD && ph.p_filesz > 0) {
			printf("- Section %d -----\n",phnum);
			printf("  Mem address : 0x%08x\n",(unsigned long)ph.p_vaddr);
			printf("  Image size  : %d bytes(0x%08x)\n",ph.p_filesz,ph.p_filesz);

			fgetpos(fout, &fpos);
			printf("  File offset : 0x%08x\n",(unsigned long)fpos);

			for(i=0 ; i<4 ; i++) fputc(0, fout);	// �]���o�C�g���G���A���m�� 

													// �]����A�h���X�̏������� 
			write_intdata(fout, (unsigned long)ph.p_vaddr, endian, flag_rev);

			fgetpos(felf, &ftmp);					// �o�C�i���f�[�^���������� 
			fseek(felf, ph.p_offset, SEEK_SET);
			if (ph.p_filesz < 32) {					// 32�o�C�g�ȉ��̃Z�N�V�����͈��k���Ȃ� 
				i = conv_sectiondata(felf, fout, ph.p_filesz, endian, flag_rev, 0);
			} else {
				i = conv_sectiondata(felf, fout, ph.p_filesz, endian, flag_rev, flag_comp);
			}
			if (i < 0) {
				tmp = (unsigned long)ph.p_filesz;
			} else {
				tmp = (unsigned long)i | 0x80000000;
			}
			fseek(felf, (long)ftmp, SEEK_SET);		// elf�t�@�C���|�C���^�𕜋A 

			fgetpos(fout, &ftmp);
			fseek(fout, (long)fpos, SEEK_SET);
			write_intdata(fout, tmp, endian, flag_rev);		// �]���o�C�g���̏������� 
			fseek(fout, (long)ftmp, SEEK_SET);		// �o�̓t�@�C���|�C���^�𕜋A 

		}
	}
	printf("-----------------\n");


	/* �G���g���A�h���X�t�B�[���h�𐶐�  */
	for(i=0 ; i<4 ; i++) fputc(0, fout);
														// �G���g���A�h���X�̏������� 
	write_intdata(fout, (unsigned long)eh.elf_entry, endian, flag_rev);


	/* �o�C�i���f�[�^�T�C�Y�̏������� */
	fgetpos(fout, &fpos);
	tmp = (unsigned long)fpos - (unsigned long)ftop;	// �f�[�^�T�C�Y 
	printf("Binary size   : %d bytes(0x%08x)\n",tmp,tmp);

	fseek(fout, (long)ftop + 4, SEEK_SET);
	write_intdata(fout, tmp, endian, flag_rev);			// �o�C�i���T�C�Y�̏������� 
	fseek(fout, (long)fpos, SEEK_SET);


	/* �y�C���[�h�f�[�^��ǉ� */
	if(fbin != NULL) {
		fgetpos(fout, &ftop);							// �w�b�_ 
		fputc(conv_bitrevers('D',flag_rev), fout);
		fputc(conv_bitrevers('A',flag_rev), fout);
		fputc(conv_bitrevers('T',flag_rev), fout);
		fputc(conv_bitrevers('A',flag_rev), fout);
		for(i=0 ; i<4 ; i++) fputc(0, fout);

		while((c = fgetc(fbin))!= EOF) {				// �f�[�^��]�� 
			fputc(conv_bitrevers(c, flag_rev), fout);
		}

		fgetpos(fout, &fpos);							// �f�[�^�T�C�Y 
		tmp = (unsigned long)fpos - (unsigned long)ftop;
		printf("Payload size  : %d bytes(0x%08x)\n",tmp,tmp);

		fseek(fout, (long)ftop + 4, SEEK_SET);
		write_intdata(fout, tmp, endian, flag_rev);		// �y�C���[�h�T�C�Y�̏������� 
		fseek(fout, (long)fpos, SEEK_SET);
	}

	return(0);
}


/***** srec�t�@�C���̍쐬 **********/
#define SREC_LINEBYTES			(16)		// srec�̂P�s�ɔ[�߂�o�C�g�� 

void conv_srecdata(FILE *fout, FILE *ftxt, unsigned long offs)
{
	int i,datanum,flag_end=0;
	unsigned char buf[SREC_LINEBYTES],sum;
	unsigned long addr = offs;

	while(flag_end == 0) {
		for(datanum=0 ; datanum<SREC_LINEBYTES ; datanum++) {
			if( (i = fgetc(fout))!= EOF) {
				buf[datanum] = (unsigned char)i;
			} else {
				break;
			}
		}
		if(datanum == 0) {				// EOF�Ȃ�G���h���R�[�h������ 
			flag_end = 1;
			addr = offs;
		}

		sum =  addr & 0xff;
		sum += (addr >> 8) & 0xff;

		if(addr < 0x10000) {			// S1,S9���R�[�h 
			if(flag_end == 0) {
				fprintf(ftxt,"S1");
			} else {
				fprintf(ftxt,"S9");
			}
			fprintf(ftxt,"%02X%04X",datanum+2+1,addr);
			sum += datanum + 2 + 1;

		} else if (addr < 0x1000000) {	// S2,S7���R�[�h 
			if(flag_end == 0) {
				fprintf(ftxt,"S2");
			} else {
				fprintf(ftxt,"S7");
			}
			fprintf(ftxt,"%02X%06X",datanum+3+1,addr);
			sum += (addr >> 16) & 0xff;
			sum += datanum + 3 + 1;

		} else {						// S3,S8���R�[�h 
			if(flag_end == 0) {
				fprintf(ftxt,"S3");
			} else {
				fprintf(ftxt,"S8");
			}
			fprintf(ftxt,"%02X%08X",datanum+4+1,addr);
			sum += (addr >> 16) & 0xff;
			sum += (addr >> 24) & 0xff;
			sum += datanum + 4 + 1;
		}

		i = 0;
		while(i < datanum) {
			fprintf(ftxt,"%02X",buf[i]);
			sum += buf[i];
			i++;
		}
		sum = ~sum;
		fprintf(ftxt,"%02X\n",sum);

		addr += datanum;
	}

}


/***** �C���e��HEX�t�@�C���̍쐬 **********/
#define IHEX_LINEBYTES			(16)		// ihex�̂P�s�ɔ[�߂�o�C�g�� 

void conv_hexdata(FILE *fout, FILE *ftxt, unsigned long offs)
{
	int i,datanum,flag_end=0;
	unsigned char buf[IHEX_LINEBYTES],sum;
	unsigned long addr = offs;
	unsigned long uaddr = offs;

	while(flag_end == 0) {
		for(datanum=0 ; datanum<IHEX_LINEBYTES ; datanum++) {
			if( (i = fgetc(fout))!= EOF) {
				buf[datanum] = (unsigned char)i;
			} else {
				break;
			}
		}

		if(datanum == 0) {				// EOF�Ȃ�G���h���R�[�h������ 
			flag_end = 1;
			fprintf(ftxt,":00000001FF\n");

		} else {						// �f�[�^���R�[�h������ 
			if(uaddr > 0x0ffff) {		// �g�����j�A�A�h���X�̑}�� 
				sum = 0x02 + 0x00 + 0x00 + 0x04;
				sum += (addr >> 16) & 0xff;
				sum += (addr >> 24) & 0xff;
				sum = (~sum) + 1;
				fprintf(ftxt,":02000004%04X%02X\n",(addr>>16)&0xffff,sum);
				uaddr = addr & 0x0ffff;
			}

			sum = datanum;
			sum += uaddr & 0xff;
			sum += (uaddr >> 8) & 0xff;
			fprintf(ftxt,":%02X%04X00",datanum,uaddr & 0xffff);
			for(i=0 ; i<datanum ; i++) {
				fprintf(ftxt,"%02X",buf[i]);
				sum += buf[i];
			}
			sum = (~sum) + 1;
			fprintf(ftxt,"%02X\n",sum);
		}

		addr += datanum;
		uaddr += datanum;
	}

}
