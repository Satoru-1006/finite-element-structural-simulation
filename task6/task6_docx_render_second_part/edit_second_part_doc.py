from docx import Document
from docx.shared import Pt
from docx.oxml.ns import qn
from docx.text.paragraph import Paragraph
from docx.oxml import OxmlElement

src = r'C:/Users/86198/Desktop/task6_formula_editable_work.docx'
out_ascii = r'C:/Users/86198/Desktop/task6_formula_second_part_done_v2.docx'
doc = Document(src)

def set_font(paragraph, name='宋体', size=12):
    for run in paragraph.runs:
        run.font.name = name
        run._element.rPr.rFonts.set(qn('w:eastAsia'), name)
        run.font.size = Pt(size)

def insert_after(paragraph, text):
    new_p = OxmlElement('w:p')
    paragraph._p.addnext(new_p)
    p = Paragraph(new_p, paragraph._parent)
    p.text = text
    set_font(p, size=12)
    return p

modeling_text = (
    '本算例在 Abaqus/CAE 中建立单根矩形截面悬臂梁模型，用于模拟构件在轴向拉伸和横向弯曲共同作用下的力学响应。'
    '构件长度取 L=1.2 m，采用二维平面梁单元 B21 建模；材料弹性模量取 E=210 GPa，矩形截面尺寸取 b×h=20 mm×40 mm，'
    '截面面积 A=8.0×10^-4 m^2，截面惯性矩 I=1.067×10^-7 m^4。模型左端设置为固定端，约束水平位移、竖向位移和转角；'
    '右端为自由端，并同时施加轴向拉力 N=10 kN 和竖向集中力 P=600 N。为考察单元数量对结果的影响，CAE 模型分别采用 1、2、4、8 个梁单元进行划分。'
    '建模过程中保持几何尺寸、材料参数、截面属性、边界条件和载荷设置与材料力学理论解及有限元程序解一致。'
)
doc.paragraphs[612].text = modeling_text
set_font(doc.paragraphs[612])

doc.paragraphs[615].text = '（此处可插入 Abaqus/CAE 中的几何模型图、边界条件与载荷图、网格图、变形图和应力/截面结果图。）'
set_font(doc.paragraphs[615])

cae_text = (
    'CAE 结果采用 8 单元模型作为表中软件解。自由端轴向位移、横向位移和转角直接由 Abaqus 位移结果 U1、U2、UR3 提取；'
    '固定端最大正应力不直接采用云图中的 Mises 最大值，而根据固定端反力与反力矩按 σmax=|RF1|/A+|RM3|c/I 回算，'
    '其中 c=h/2=0.02 m。Abaqus 反力结果为 RF1=-10000 N、RF2=600 N、RM3=720 N·m，因此固定端最大正应力为 147.5 MPa。'
)
doc.paragraphs[617].text = cae_text
set_font(doc.paragraphs[617])

# Table 7: fill by row number to avoid hidden characters in labels
vals7 = ['0.07143 mm', '-15.4275 mm', '-1.92857×10^-2 rad', '147.50 MPa']
tbl7 = doc.tables[7]
for idx, val in enumerate(vals7, start=1):
    tbl7.rows[idx].cells[1].text = val

# Table 8: full comparison table
vals8 = [
    ['理论解', '-', '0.07143 mm', '-15.4286 mm', '-1.92857×10^-2 rad', '147.50 MPa'],
    ['程序解', '1', '0.07143 mm', '-15.42857 mm', '-1.92857×10^-2 rad', '147.50 MPa'],
    ['程序解', '2', '0.07143 mm', '-15.42857 mm', '-1.92857×10^-2 rad', '147.50 MPa'],
    ['程序解', '4', '0.07143 mm', '-15.42857 mm', '-1.92857×10^-2 rad', '147.50 MPa'],
    ['程序解', '8', '0.07143 mm', '-15.42857 mm', '-1.92857×10^-2 rad', '147.50 MPa'],
    ['CAE 解', '8 单元', '0.07143 mm', '-15.4275 mm', '-1.92857×10^-2 rad', '147.50 MPa'],
]
tbl8 = doc.tables[8]
for r, row_vals in enumerate(vals8, start=1):
    for c, val in enumerate(row_vals):
        tbl8.rows[r].cells[c].text = val

for tbl in [tbl7, tbl8]:
    for row in tbl.rows:
        for cell in row.cells:
            for p in cell.paragraphs:
                set_font(p, size=10.5)

analysis_text = (
    '分析：由对比结果可知，CAE 解与理论解、程序解在轴向位移、转角和固定端最大正应力方面基本一致。'
    '横向位移随单元数增加逐渐接近理论值，8 单元模型得到 -15.4275 mm，与理论值 -15.4286 mm 极为接近。'
    '误差主要来源于梁单元离散、结果提取位置以及应力后处理方式。对于固定端最大正应力，应采用轴力与固定端弯矩叠加计算，'
    '不宜直接将 Abaqus 云图中的 Mises 应力最大值作为理论对比值。'
)
insert_after(doc.paragraphs[624], analysis_text)

doc.save(out_ascii)
print(out_ascii)
