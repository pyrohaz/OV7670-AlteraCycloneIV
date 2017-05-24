/*
 * Created by SharpDevelop.
 * User: harri
 * Date: 20/05/2017
 * Time: 02:30
 * 
 * To change this template use Tools | Options | Coding | Edit Standard Headers.
 */
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO.Ports;
using System.Threading;
using System.Windows.Forms;

namespace CameraViewT1
{
	public partial class MainForm : Form
	{
		SerialPort sp = null;
		Thread spthread = null;
		uint[] frame;
		public MainForm()
		{
			InitializeComponent();
			frame = new uint[640*480];
			pictureBox1.Image = new Bitmap(640, 480, PixelFormat.Format16bppRgb565);
			
			if(SerialPort.GetPortNames().Length>0){
				//sp = new SerialPort(SerialPort.GetPortNames()[0], 1228800);
				sp = new SerialPort(SerialPort.GetPortNames()[0], 6000000);
				sp.ReadTimeout = -1;
				sp.ReceivedBytesThreshold = sp.ReadBufferSize = 640*480*2+10;
				sp.Open();
				sp.DiscardInBuffer();
				spthread = new Thread(new ThreadStart(SpThread));
				spthread.Start();
				
				Debug.WriteLine(sp.PortName);
			}
			else{
				MessageBox.Show("No COM ports.");
			}
		}
		
		uint[] IDCT(Int16[] array){
			double[,] coeff = {
				{0.354, 0.354, 0.354, 0.354, 0.354, 0.354, 0.354, 0.354},
				{0.490, 0.416, 0.278, 0.098, -0.098, -0.278, -0.416, -0.490},
				{0.462, 0.191, -0.191, -0.462, -0.462, -0.191, 0.191, 0.462},
				{0.416, -0.098, -0.490, -0.278, 0.278, 0.490, 0.098, -0.416},
				{0.354, -0.354, -0.354, 0.354, 0.354, -0.354, -0.354, 0.354},
				{0.278, -0.490, 0.098, 0.416, -0.416, -0.098, 0.490, -0.278},
				{0.191, -0.462, 0.462, -0.191, -0.191, 0.462, -0.462, 0.191},
				{0.098, -0.278, 0.416, -0.490, 0.490, -0.416, 0.278, -0.098}
			};
			
			uint[] outv = new uint[8];
			double sum = 0;
			
			for(int n = 0; n<8; n++){
				sum = 0;
				for(int m = 0; m<8; m++){
					sum += ((double)array[m])*(coeff[n,m]);
				}
				
				sum = sum*255/31;
				
				if(sum<0) outv[n] = 0;
				else if(sum<255) outv[n] = (uint) sum;
				else outv[n] = 255;
			}
			
			return outv;
		}
		
		int XPIX = 640;
		int YPIX = 480;
		
		int fc = 0;
		long ms1;
		double fps;
		void SpThread(){
			byte[] btr = new byte[640*480*2];
			ms1 = 0;
			while(true){
				Debug.WriteLine("New frame " + fc);
				int bytes = 0;
				while(sp.BytesToRead<XPIX*YPIX*2){
					bytes = sp.BytesToRead;
					Thread.Sleep(10);
					Debug.WriteLine(sp.BytesToRead);
					
					if(bytes == sp.BytesToRead) sp.Write(new byte[1]{0xaa}, 0, 1);
					while(sp.BytesToWrite>0) Thread.Sleep(2);
				}
				
				sp.Read(btr, 0, XPIX*YPIX*2);
				
				for(int n = 0; n<XPIX*YPIX*2; n+=2){
					//uint v = (uint)BitConverter.ToUInt16(new byte[2]{btr[n], btr[n+1]}, 0);
					uint v = (uint)BitConverter.ToUInt16(new byte[2]{btr[n+1], btr[n]}, 0);
					frame[n/2] = v;
				}
				/*
				sp.Write(new byte[1]{0xaa}, 0, 1);
				while(sp.BytesToWrite>0) Thread.Sleep(2);
				
				int bytes = 0;
				while(sp.BytesToRead<640*480){
					bytes = sp.BytesToRead;
					Thread.Sleep(10);
					Debug.WriteLine(sp.BytesToRead);
					
					if(bytes == sp.BytesToRead) sp.Write(new byte[1]{0xaa}, 0, 1);
					while(sp.BytesToWrite>0) Thread.Sleep(2);
				}
				
				sp.Read(btr, 0, 640*480);
				
				for(int n = 0; n<640*480; n++){
					frame[n] = btr[n];
				}*/
				
				
				/*while(sp.BytesToRead<480*(640*2*3/8)){
					Thread.Sleep(100);
					Debug.WriteLine(sp.BytesToRead);
				}
				
				sp.Read(btr, 0, 480*(640*2*3/8));
				
				uint fpos = 0;
				uint[] rp, gp, bp;
				Int16[] pb = new Int16[8];
				
				pb[2]=pb[3]=pb[4]=pb[5]=pb[6]=pb[7] = 0;
				for(int n = 0; n<480*(640*2*3/8); n+=6){
					pb[0] = Convert.ToInt16(btr[n]);
					pb[1] = Convert.ToInt16(btr[n+1]);
					rp = IDCT(pb);
					
					pb[0] = Convert.ToInt16(btr[n+2]);
					pb[1] = Convert.ToInt16(btr[n+3]);
					gp = IDCT(pb);
					
					pb[0] = Convert.ToInt16(btr[n+4]);
					pb[1] = Convert.ToInt16(btr[n+5]);
					bp = IDCT(pb);
					
					for(int m = 0; m<8; m++){
						uint pix = (bp[m]) | (gp[m]<<8) | (rp[m]<<16);
						frame[fpos++] = pix;
					}
				}*/
				
				if((int)Invoke(new Func<int>(() => tabControl1.SelectedIndex)) == 1){
					richTextBox1.Invoke(new Action(() => richTextBox1.Text = string.Join(" ", frame)));
				}
				else{
					pictureBox1.Invoke(new Action(pictureBox1.Invalidate));
				}
				fps = 1000/(double)((long)(DateTime.Now - new DateTime(1970, 1, 1)).TotalMilliseconds - ms1);
				ms1 = (long)(DateTime.Now - new DateTime(1970, 1, 1)).TotalMilliseconds;
				labelframe.Invoke(new Action(() => labelframe.Text = fc.ToString()));
				labelfps.Invoke(new Action(() => labelfps.Text = fps.ToString()));
				
				fc++;
				sp.DiscardInBuffer();
				Thread.Sleep(10);
			}
		}
		
		
		void PictureBox1Paint(object sender, PaintEventArgs e)
		{
			uint r,g,b;
			uint pix;
			
			/*for(int y = 0; y<480; y++){
				for(int x = 0; x<640; x++){
					pix = frame[x+y*640];
					((Bitmap)pictureBox1.Image).SetPixel(x,y,Color.FromArgb(255,(int)(pix>>16)&255,(int)(pix>>16)&255,(int)pix&255));
				}
			}*/
			
			for(int y = 0; y<480; y++){
				for(int x = 0; x<640; x++){
					pix = frame[x*XPIX/640+y*XPIX];
					//pix = frame[(x>>2) + (y>>2)*XPIX];
					//pix = frame[x + y*XPIX];
					r = (pix>>11)*255/31;
					g = ((pix>>5)&63)*255/63;
					b = (pix&31)*255/31;
					//r = (pix>>5)*255/7;
					//g = ((pix>>2)&7)*255/7;
					//b = (pix&3)*255/3;
					((Bitmap)pictureBox1.Image).SetPixel(x,y,Color.FromArgb(255,(int)r,(int)g,(int)b));
				}
			}
			
			/*for(int y = 0; y<480; y++){
				for(int x = 0; x<640; x++){
					//pix = frame[(x>>1)+(y>>1)*320];
					pix = frame[x+y*640];
					r = (pix>>5)*255/7;
					g = ((pix>>2)&7)*255/7;
					b = (pix&3)*255/3;
					//r = pix & 0xE0;
					//g = ((pix>>2)&7)<<5;
					//b = (pix&3)<<6;
					((Bitmap)pictureBox1.Image).SetPixel(x,y,Color.FromArgb(255,(int)r,(int)g,(int)b));
				}
			}*/
		}
		
		void MainFormFormClosing(object sender, FormClosingEventArgs e)
		{
			if(spthread != null && spthread.IsAlive){
				spthread.Abort();
				spthread.Join();
			}
			
			if(sp != null && sp.IsOpen){
				sp.Close();
			}
		}
	}
}


