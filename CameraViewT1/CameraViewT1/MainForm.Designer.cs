/*
 * Created by SharpDevelop.
 * User: harri
 * Date: 20/05/2017
 * Time: 02:30
 * 
 * To change this template use Tools | Options | Coding | Edit Standard Headers.
 */
namespace CameraViewT1
{
	partial class MainForm
	{
		/// <summary>
		/// Designer variable used to keep track of non-visual components.
		/// </summary>
		private System.ComponentModel.IContainer components = null;
		private System.Windows.Forms.PictureBox pictureBox1;
		private System.Windows.Forms.RichTextBox richTextBox1;
		private System.Windows.Forms.TabControl tabControl1;
		private System.Windows.Forms.TabPage tabPage1;
		private System.Windows.Forms.TabPage tabPage2;
		private System.Windows.Forms.Label label1;
		private System.Windows.Forms.Label labelframe;
		private System.Windows.Forms.Label labelfps;
		private System.Windows.Forms.Label label3;
		
		/// <summary>
		/// Disposes resources used by the form.
		/// </summary>
		/// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
		protected override void Dispose(bool disposing)
		{
			if (disposing) {
				if (components != null) {
					components.Dispose();
				}
			}
			base.Dispose(disposing);
		}
		
		/// <summary>
		/// This method is required for Windows Forms designer support.
		/// Do not change the method contents inside the source code editor. The Forms designer might
		/// not be able to load this method if it was changed manually.
		/// </summary>
		private void InitializeComponent()
		{
			this.pictureBox1 = new System.Windows.Forms.PictureBox();
			this.tabControl1 = new System.Windows.Forms.TabControl();
			this.tabPage1 = new System.Windows.Forms.TabPage();
			this.tabPage2 = new System.Windows.Forms.TabPage();
			this.richTextBox1 = new System.Windows.Forms.RichTextBox();
			this.label1 = new System.Windows.Forms.Label();
			this.labelframe = new System.Windows.Forms.Label();
			this.labelfps = new System.Windows.Forms.Label();
			this.label3 = new System.Windows.Forms.Label();
			((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).BeginInit();
			this.tabControl1.SuspendLayout();
			this.tabPage1.SuspendLayout();
			this.tabPage2.SuspendLayout();
			this.SuspendLayout();
			// 
			// pictureBox1
			// 
			this.pictureBox1.BackColor = System.Drawing.SystemColors.ControlDark;
			this.pictureBox1.Location = new System.Drawing.Point(6, 6);
			this.pictureBox1.Name = "pictureBox1";
			this.pictureBox1.Size = new System.Drawing.Size(640, 480);
			this.pictureBox1.TabIndex = 0;
			this.pictureBox1.TabStop = false;
			this.pictureBox1.Paint += new System.Windows.Forms.PaintEventHandler(this.PictureBox1Paint);
			// 
			// tabControl1
			// 
			this.tabControl1.Controls.Add(this.tabPage1);
			this.tabControl1.Controls.Add(this.tabPage2);
			this.tabControl1.Location = new System.Drawing.Point(13, 13);
			this.tabControl1.Name = "tabControl1";
			this.tabControl1.SelectedIndex = 0;
			this.tabControl1.Size = new System.Drawing.Size(661, 520);
			this.tabControl1.TabIndex = 1;
			// 
			// tabPage1
			// 
			this.tabPage1.Controls.Add(this.pictureBox1);
			this.tabPage1.Location = new System.Drawing.Point(4, 22);
			this.tabPage1.Name = "tabPage1";
			this.tabPage1.Padding = new System.Windows.Forms.Padding(3);
			this.tabPage1.Size = new System.Drawing.Size(653, 494);
			this.tabPage1.TabIndex = 0;
			this.tabPage1.Text = "Image";
			this.tabPage1.UseVisualStyleBackColor = true;
			// 
			// tabPage2
			// 
			this.tabPage2.Controls.Add(this.richTextBox1);
			this.tabPage2.Location = new System.Drawing.Point(4, 22);
			this.tabPage2.Name = "tabPage2";
			this.tabPage2.Padding = new System.Windows.Forms.Padding(3);
			this.tabPage2.Size = new System.Drawing.Size(653, 494);
			this.tabPage2.TabIndex = 1;
			this.tabPage2.Text = "Pixels";
			this.tabPage2.UseVisualStyleBackColor = true;
			// 
			// richTextBox1
			// 
			this.richTextBox1.Location = new System.Drawing.Point(7, 7);
			this.richTextBox1.Name = "richTextBox1";
			this.richTextBox1.Size = new System.Drawing.Size(640, 481);
			this.richTextBox1.TabIndex = 0;
			this.richTextBox1.Text = "";
			// 
			// label1
			// 
			this.label1.Location = new System.Drawing.Point(680, 35);
			this.label1.Name = "label1";
			this.label1.Size = new System.Drawing.Size(54, 23);
			this.label1.TabIndex = 3;
			this.label1.Text = "Frame: ";
			// 
			// labelframe
			// 
			this.labelframe.Location = new System.Drawing.Point(740, 35);
			this.labelframe.Name = "labelframe";
			this.labelframe.Size = new System.Drawing.Size(54, 23);
			this.labelframe.TabIndex = 4;
			this.labelframe.Text = "0";
			// 
			// labelfps
			// 
			this.labelfps.Location = new System.Drawing.Point(740, 58);
			this.labelfps.Name = "labelfps";
			this.labelfps.Size = new System.Drawing.Size(54, 23);
			this.labelfps.TabIndex = 6;
			this.labelfps.Text = "0";
			// 
			// label3
			// 
			this.label3.Location = new System.Drawing.Point(680, 58);
			this.label3.Name = "label3";
			this.label3.Size = new System.Drawing.Size(54, 23);
			this.label3.TabIndex = 5;
			this.label3.Text = "FPS:";
			// 
			// MainForm
			// 
			this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
			this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
			this.ClientSize = new System.Drawing.Size(831, 546);
			this.Controls.Add(this.labelfps);
			this.Controls.Add(this.label3);
			this.Controls.Add(this.labelframe);
			this.Controls.Add(this.label1);
			this.Controls.Add(this.tabControl1);
			this.Name = "MainForm";
			this.Text = "CameraViewT1";
			this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.MainFormFormClosing);
			((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).EndInit();
			this.tabControl1.ResumeLayout(false);
			this.tabPage1.ResumeLayout(false);
			this.tabPage2.ResumeLayout(false);
			this.ResumeLayout(false);

		}
	}
}
