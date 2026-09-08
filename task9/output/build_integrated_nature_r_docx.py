import importlib.util
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
from docx.shared import Pt, RGBColor, Cm


ROOT = Path(r"C:\Users\86198\Desktop\task9")
OUT = ROOT / "output"
BASE_SCRIPT = OUT / "build_final_nature_docx.py"
FINAL_DOCX = OUT / "final_paper_nature_style_academic_optimized_v8.docx"

spec = importlib.util.spec_from_file_location("base_docx", BASE_SCRIPT)
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)


CROP = OUT / "cropped_figures"


def m_el(tag):
    return OxmlElement(f"m:{tag}")


def m_text(text):
    r = m_el("r")
    t = m_el("t")
    t.text = text
    r.append(t)
    return r


def m_sup(base_txt, sup_txt):
    el = m_el("sSup")
    e = m_el("e")
    sup = m_el("sup")
    e.append(m_text(base_txt))
    sup.append(m_text(sup_txt))
    el.append(e)
    el.append(sup)
    return el


def m_sub(base_txt, sub_txt):
    el = m_el("sSub")
    e = m_el("e")
    sub = m_el("sub")
    e.append(m_text(base_txt))
    sub.append(m_text(sub_txt))
    el.append(e)
    el.append(sub)
    return el


def m_subsup(base_txt, sub_txt, sup_txt):
    el = m_el("sSubSup")
    e = m_el("e")
    sub = m_el("sub")
    sup = m_el("sup")
    e.append(m_text(base_txt))
    sub.append(m_text(sub_txt))
    sup.append(m_text(sup_txt))
    el.append(e)
    el.append(sub)
    el.append(sup)
    return el


def m_frac(num, den):
    f = m_el("f")
    num_el = m_el("num")
    den_el = m_el("den")
    num_el.append(m_text(num))
    den_el.append(m_text(den))
    f.append(num_el)
    f.append(den_el)
    return f


def m_frac_seq(num_parts, den_parts):
    f = m_el("f")
    num_el = m_el("num")
    den_el = m_el("den")
    for item in m_seq(num_parts):
        num_el.append(item)
    for item in m_seq(den_parts):
        den_el.append(item)
    f.append(num_el)
    f.append(den_el)
    return f


def m_matrix(rows):
    mat = m_el("m")
    for row in rows:
        mr = m_el("mr")
        for cell_parts in row:
            e = m_el("e")
            parts = cell_parts if isinstance(cell_parts, list) else [cell_parts]
            for item in m_seq(parts):
                e.append(item)
            mr.append(e)
        mat.append(mr)
    return mat


def m_delim(content, beg="[", end="]"):
    d = m_el("d")
    dpr = m_el("dPr")
    beg_chr = m_el("begChr")
    beg_chr.set(qn("m:val"), beg)
    end_chr = m_el("endChr")
    end_chr.set(qn("m:val"), end)
    dpr.append(beg_chr)
    dpr.append(end_chr)
    e = m_el("e")
    e.append(content)
    d.append(dpr)
    d.append(e)
    return d


def m_seq(parts):
    out = []
    for part in parts:
        if isinstance(part, str):
            out.append(m_text(part))
        else:
            out.append(part)
    return out


def add_math_equation(doc, parts, num):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(4)
    omath_para = m_el("oMathPara")
    omath = m_el("oMath")
    for item in m_seq(parts):
        omath.append(item)
    omath.append(m_text(f"    （{num}）"))
    omath_para.append(omath)
    p._p.append(omath_para)
    return p


def add_picture_fit(doc, path, caption, width_cm=7.25):
    if not Path(path).exists():
        return
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(0)
    run = p.add_run()
    run.add_picture(str(path), width=Cm(width_cm))
    base.add_caption(doc, caption, kind="figure")


def compact_comparison_rows():
    return [
        [
            "u / 10⁻⁴ m",
            "理论：1.190, 2.381, 3.571\n2 单元：1.100, 2.201, 3.373\n4 单元：1.062, 2.273, 3.462\n8 单元：1.129, 2.258, 3.453\n说明：整体偏小，约 5%–11%",
        ],
        [
            "σx / MPa",
            "理论：100, 100, 100\n2 单元：101.6, 100.0, 98.43\n4 单元：100.0, 100.97, 100.0\n8 单元：99.51, 100.0, 100.36\n说明：接近理论值，误差约 2% 内",
        ],
        [
            "σy / MPa",
            "理论：0, 0, 0\n2 单元：30.47, 15.11, −0.25\n4 单元：15.16, 0.62, 0.17\n8 单元：15.58, 5.46, −0.05\n说明：固定端限制泊松收缩",
        ],
        [
            "τxy / MPa",
            "理论：0, 0, 0\n2 单元：0.63, 0, −0.63\n4 单元：0, 0.78, 0\n8 单元：0.47, 0.40, −0.38\n说明：边界扰动和网格剖分影响",
        ],
    ]


def set_table_no_split(table):
    for row in table.rows:
        tr_pr = row._tr.get_or_add_trPr()
        cant_split = OxmlElement("w:cantSplit")
        tr_pr.append(cant_split)
        for cell in row.cells:
            for p in cell.paragraphs:
                p.paragraph_format.keep_together = True
                p.style = "Normal"
                p.paragraph_format.first_line_indent = None
                p.paragraph_format.left_indent = None
                p.paragraph_format.space_before = Pt(0)
                p.paragraph_format.space_after = Pt(0)


def init_doc():
    doc = Document()
    base.set_page(doc.sections[0], columns=1)
    base.add_page_number(doc.sections[0])
    styles = doc.styles
    styles["Normal"].font.name = "Times New Roman"
    styles["Normal"]._element.rPr.rFonts.set(qn("w:eastAsia"), "宋体")
    styles["Normal"].font.size = Pt(10.5)
    for style_name in ["Heading 1", "Heading 2"]:
        styles[style_name].font.name = "Times New Roman"
        styles[style_name]._element.rPr.rFonts.set(qn("w:eastAsia"), "宋体")
        styles[style_name].font.color.rgb = RGBColor(0, 0, 0)
    return doc


def add_title_front(doc):
    # Nature-like first page: masthead, article type, title, authors, affiliation,
    # then a compact abstract. This is an academic-course adaptation, not a
    # journal template clone.
    mast = doc.add_paragraph()
    mast.paragraph_format.space_before = Pt(0)
    mast.paragraph_format.space_after = Pt(0)
    mast.alignment = WD_ALIGN_PARAGRAPH.LEFT
    r = mast.add_run("nature")
    base.set_run_font(r, size=26, bold=True, name="Times New Roman", east="宋体")
    r2 = mast.add_run("  scientific report")
    base.set_run_font(r2, size=9, bold=False, name="Times New Roman", east="宋体", color="666666")

    rule = doc.add_paragraph()
    rule.paragraph_format.space_before = Pt(2)
    rule.paragraph_format.space_after = Pt(8)
    rr = rule.add_run(" " * 110)
    base.set_run_font(rr, size=2, color="C00000")
    ppr = rule._p.get_or_add_pPr()
    pbdr = OxmlElement("w:pBdr")
    bottom = OxmlElement("w:bottom")
    bottom.set(qn("w:val"), "single")
    bottom.set(qn("w:sz"), "12")
    bottom.set(qn("w:space"), "1")
    bottom.set(qn("w:color"), "C00000")
    pbdr.append(bottom)
    ppr.append(pbdr)

    article_type = doc.add_paragraph()
    article_type.paragraph_format.space_before = Pt(0)
    article_type.paragraph_format.space_after = Pt(5)
    r = article_type.add_run("ARTICLE | FINITE ELEMENT ANALYSIS COURSE REPORT")
    base.set_run_font(r, size=8.5, bold=True, name="Times New Roman", east="宋体", color="C00000")

    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.LEFT
    title.paragraph_format.space_before = Pt(0)
    title.paragraph_format.space_after = Pt(5)
    r = title.add_run("基于三角形常应变单元的矩形方板拉伸有限元分析")
    base.set_run_font(r, size=18, bold=True, name="Times New Roman", east="宋体")

    authors = doc.add_paragraph()
    authors.paragraph_format.space_before = Pt(0)
    authors.paragraph_format.space_after = Pt(3)
    r = authors.add_run("赵晓钧，侯冰洋，郑海洋")
    base.set_run_font(r, size=10.5, bold=True, name="Times New Roman", east="宋体")

    aff = doc.add_paragraph()
    aff.paragraph_format.space_before = Pt(0)
    aff.paragraph_format.space_after = Pt(3)
    r = aff.add_run("天津科技大学机械工程学院")
    base.set_run_font(r, size=9.5, name="Times New Roman", east="宋体", color="333333")

    guide = doc.add_paragraph()
    guide.paragraph_format.space_before = Pt(0)
    guide.paragraph_format.space_after = Pt(6)
    r = guide.add_run("指导教师：李建宇    课程：有限元分析    任务编号：9")
    base.set_run_font(r, size=9.5, name="Times New Roman", east="宋体", color="333333")

    doi = doc.add_paragraph()
    doi.paragraph_format.space_before = Pt(0)
    doi.paragraph_format.space_after = Pt(6)
    r = doi.add_run("Received: 2026-06-03    Revised: 2026-06-04    Course manuscript")
    base.set_run_font(r, size=8.5, name="Times New Roman", east="宋体", color="777777")

    abstract_label = doc.add_paragraph()
    abstract_label.paragraph_format.space_before = Pt(2)
    abstract_label.paragraph_format.space_after = Pt(3)
    r = abstract_label.add_run("摘要")
    base.set_run_font(r, size=11, bold=True, name="Times New Roman", east="宋体")

    base.add_text(
        doc,
        "矩形方板拉伸问题为平面弹性有限元方法提供了可验证的基准模型。本文针对左边界固定、右边界承受 x 方向均布拉应力、上下边界自由的矩形薄板，在平面应力假设下建立三节点三角形常应变单元模型。研究首先由虚功原理和最小势能原理得到有限元弱形式，随后推导位移插值、形函数矩阵、应变-位移矩阵、平面应力本构矩阵、单元刚度矩阵及右边界均布拉力的等效节点载荷。基于 MATLAB 实现总体刚度矩阵组装、位移边界条件处理、节点位移求解和单元应力后处理，并将数值结果与均匀拉伸理论解进行对比。结果表明，x 方向位移沿板长方向单调增大，y 方向位移反映泊松收缩及固定端约束的共同作用；板中部 σx 接近 100 MPa 理论拉应力，而固定端附近出现非零 σy 和 τxy。该偏差源于常应变三角形单元的低阶近似、网格离散以及完全固定边界对横向变形的限制。",
        first_line=False,
    )
    kw = doc.add_paragraph()
    kw.paragraph_format.space_before = Pt(6)
    kw.paragraph_format.space_after = Pt(0)
    r = kw.add_run("关键词：")
    base.set_run_font(r, size=9.5, bold=True, name="Times New Roman", east="宋体")
    r = kw.add_run("有限元法；三角形常应变单元；平面应力；矩形方板；MATLAB；应力分析")
    base.set_run_font(r, size=9.5, name="Times New Roman", east="宋体")

    sec = doc.add_section(WD_SECTION.CONTINUOUS)
    base.set_page(sec, columns=2)
    sec.footer.is_linked_to_previous = True


def add_main_text(doc):
    base.add_heading(doc, "1 引言", 1)
    base.add_text(doc, "拉伸薄板的位移和应力分布是平面弹性理论与有限元方法中的基础问题。对于无限远离边界扰动的均匀拉伸区域，解析解可将应力场近似为 σx=q、σy=0、τxy=0，并由材料本构关系给出相应的轴向伸长和横向收缩。然而，工程中的边界条件通常并非理想自由收缩状态。例如，若左边界被完全固定，泊松收缩受到抑制，固定端附近会产生二维应力扰动，简单的一维均匀拉伸解难以描述这种局部响应。")
    base.add_text(doc, "有限元方法的优势在于将连续体区域离散为有限数量的单元，并通过节点自由度建立可求解的代数方程组。与直接求解偏微分方程强形式相比，基于虚功原理或能量原理的弱形式降低了对位移近似函数连续性的要求，使仅满足位移连续的低阶三角形单元也可用于平面弹性分析。")
    base.add_text(doc, "本文以矩形方板拉伸为对象，采用三节点三角形常应变单元建立平面应力有限元模型。文章围绕理论推导、数值实现与结果验证三条线索展开：首先给出平面弹性有限元弱形式；其次推导 CST 单元的位移插值、B 矩阵、D 矩阵、刚度矩阵和等效节点载荷；最后利用 MATLAB 程序计算节点位移和单元应力，并与理论均匀拉伸解进行对比。")

    base.add_heading(doc, "2 理论基础", 1)
    base.add_heading(doc, "2.1 平面弹性问题基本假设", 2)
    base.add_text(doc, "矩形板长度为 L，高度为 H，厚度为 t。材料视为线弹性各向同性材料，弹性模量为 E，泊松比为 ν。由于厚度方向尺寸远小于面内尺寸，并且外载荷主要作用于板面内，模型采用平面应力假设。体力项被忽略，右边界沿 x 方向的均布拉应力 q 通过边界等效节点力进入总体载荷向量。")
    base.add_heading(doc, "2.2 虚功原理与最小势能原理", 2)
    base.add_text(doc, "平面弹性有限元方程可从虚功原理建立。对任意满足位移边界条件的虚位移，结构内部应力虚功等于外载荷虚功。")
    add_math_equation(doc, ["∫Ω ", m_sup("δε", "T"), "σ dΩ = ∫Ω ", m_sup("δu", "T"), "b dΩ + ∫", m_sub("Γ", "t"), " ", m_sup("δu", "T"), "t̄ dΓ"], 1)
    base.add_text(doc, "对于稳定线弹性结构，最小势能原理与虚功原理等价。真实位移场在许可位移集合中使总势能取极小值。")
    add_math_equation(doc, ["Π(u) = ", m_frac("1", "2"), "∫Ω ", m_sup("ε", "T"), "Dε dΩ − ∫Ω ", m_sup("u", "T"), "b dΩ − ∫", m_sub("Γ", "t"), " ", m_sup("u", "T"), "t̄ dΓ"], 2)
    base.add_text(doc, "弱形式只要求位移场具有一阶导数，因此适合采用位移连续但导数不连续的常见有限元插值。三节点三角形单元在相邻单元之间满足 C0 位移连续性，但不保证应变连续性，因而更适合通过弱形式而非强形式求解。")
    base.add_heading(doc, "2.3 平面应力本构关系", 2)
    base.add_text(doc, "小变形线弹性条件下，平面应力本构关系写为：")
    add_math_equation(doc, [
        "σ = Dε,   D = ",
        m_frac_seq(["E"], ["1 − ", m_sup("ν", "2")]),
        m_delim(m_matrix([
            [["1"], ["ν"], ["0"]],
            [["ν"], ["1"], ["0"]],
            [["0"], ["0"], [m_frac("1 − ν", "2")]],
        ]), "[", "]")
    ], 3)

    base.add_heading(doc, "3 三角形常应变单元理论", 1)
    base.add_heading(doc, "3.1 节点自由度与位移插值", 2)
    base.add_text(doc, "三节点三角形单元由节点 i、j、m 构成，每个节点包含 x 与 y 两个方向位移自由度。单元节点位移向量为 de=[ui,vi,uj,vj,um,vm]ᵀ。单元内位移采用一次多项式近似。")
    add_math_equation(doc, ["u(x,y) = ", m_sub("a", "1"), " + ", m_sub("a", "2"), "x + ", m_sub("a", "3"), "y,   v(x,y) = ", m_sub("a", "4"), " + ", m_sub("a", "5"), "x + ", m_sub("a", "6"), "y"], 4)
    base.add_text(doc, "一次位移模式含六个待定系数，正好与三节点三角形单元的六个节点位移自由度对应，因此可由节点位移唯一确定单元内部位移场。该位移模式能够表示刚体位移和常应变状态，满足低阶位移型单元的基本要求。")
    base.add_heading(doc, "3.2 形函数矩阵", 2)
    add_math_equation(doc, [
        m_sup("{u, v}", "T"), " = N", m_sub("d", "e"), ",   N = ",
        m_delim(m_matrix([
            [[m_sub("N", "i")], ["0"], [m_sub("N", "j")], ["0"], [m_sub("N", "m")], ["0"]],
            [["0"], [m_sub("N", "i")], ["0"], [m_sub("N", "j")], ["0"], [m_sub("N", "m")]],
        ]), "[", "]")
    ], 5)
    base.add_text(doc, "形函数表示节点位移对单元内部位移场的贡献。线性三角形形函数满足节点插值性质和单位分解性质，即在自身节点取 1、其他节点取 0，且 Ni+Nj+Nm=1。")
    base.add_heading(doc, "3.3 应变-位移矩阵", 2)
    add_math_equation(doc, ["ε = [", m_sub("ε", "x"), ", ", m_sub("ε", "y"), ", ", m_sub("γ", "xy"), "]ᵀ = [", m_frac("∂u", "∂x"), ", ", m_frac("∂v", "∂y"), ", ", m_frac("∂u", "∂y"), " + ", m_frac("∂v", "∂x"), "]ᵀ = B", m_sub("d", "e")], 6)
    add_math_equation(doc, [
        "B = ", m_frac("1", "2A"),
        m_delim(m_matrix([
            [[m_sub("b", "i")], ["0"], [m_sub("b", "j")], ["0"], [m_sub("b", "m")], ["0"]],
            [["0"], [m_sub("c", "i")], ["0"], [m_sub("c", "j")], ["0"], [m_sub("c", "m")]],
            [[m_sub("c", "i")], [m_sub("b", "i")], [m_sub("c", "j")], [m_sub("b", "j")], [m_sub("c", "m")], [m_sub("b", "m")]],
        ]), "[", "]")
    ], 7)
    base.add_text(doc, "A 为三角形面积，b 和 c 系数由节点坐标差确定。由于形函数为一次函数，其导数为常数，因此 B 矩阵在单元内部保持不变。由此得到的单元应变和应力均为常值，这也是该单元被称为常应变单元的原因。")
    base.add_heading(doc, "3.4 单元刚度矩阵", 2)
    add_math_equation(doc, [m_sub("K", "e"), " = ∫", m_sub("Ω", "e"), " ", m_sup("B", "T"), " × D × B × t dΩ = t × A × ", m_sup("B", "T"), " × D × B"], 8)
    base.add_heading(doc, "3.5 等效节点载荷向量", 2)
    base.add_text(doc, "连续分布载荷应通过虚功等效原则转换为节点载荷。对于右边界长度为 Le 的线性边界段，若均布拉应力 q 沿 x 方向作用，则两端节点在 x 自由度上的等效节点力为：")
    add_math_equation(doc, [
        m_sub("f", "e"), " = ∫", m_sub("Γ", "e"), " ", m_sup("N", "T"), " × t̄ × t dΓ,   ",
        m_sub("f", "e"), " = ",
        m_delim(m_matrix([
            [[m_frac_seq(["q × t × ", m_sub("L", "e")], ["2"])]],
            [["0"]],
            [[m_frac_seq(["q × t × ", m_sub("L", "e")], ["2"])]],
            [["0"]],
        ]), "[", "]")
    ], 9)


def add_model_results(doc):
    import json
    summary = json.loads((ROOT / "results_summary.json").read_text(encoding="utf-8"))
    params = summary["parameters"]
    mesh = summary["mesh"]
    theory = summary["theory"]
    abaqus = summary["abaqus_results"]
    load = summary["load"]

    figs = {
        "mesh": CROP / "fig_mesh_matlab.png",
        "bc": CROP / "fig_bc.png",
        "flow": CROP / "image8.png",
        "deform": CROP / "fig_deformed_matlab.png",
        "ux": CROP / "fig_ux_matlab.png",
        "uy": CROP / "fig_uy_matlab.png",
        "line": CROP / "fig_s11_line.png",
        "s11": CROP / "fig_s11_smooth.png",
        "s22": CROP / "fig_s22_smooth.png",
        "s12": CROP / "fig_s12_smooth.png",
        "const": CROP / "fig_s11_const.png",
        "ra": CROP / "figA_displacement_validation.png",
        "rb": CROP / "figB_stress_components.png",
        "rc": CROP / "figC_error_sources.png",
    }

    base.add_heading(doc, "4 矩形方板有限元模型", 1)
    base.add_heading(doc, "4.1 几何模型与材料参数", 2)
    base.add_text(doc, "模型采用长度 L=1.0 m、高度 H=0.4 m、厚度 t=0.01 m 的矩形薄板。材料参数为 E=210 GPa、ν=0.30，右端均布拉应力 q=100 MPa。单元类型为三节点三角形平面应力单元，理论上对应 CST，Abaqus 模型中对应 CPS3。")
    base.add_table(
        doc,
        "表 1 矩形方板有限元模型参数",
        ["参数", "取值", "说明"],
        [
            ["L", f"{params['L_m']:.3f} m", "板长"],
            ["H", f"{params['H_m']:.3f} m", "板高"],
            ["t", f"{params['t_m']:.3f} m", "厚度"],
            ["E", f"{params['E_Pa']/1e9:.1f} GPa", "弹性模量"],
            ["ν", f"{params['nu']:.2f}", "泊松比"],
            ["q", f"{params['q_Pa']/1e6:.1f} MPa", "右端均布拉应力"],
            ["单元", "CST / CPS3", "三节点三角形平面应力单元"],
        ],
        widths=[1700, 2300, 3600],
    )
    base.add_heading(doc, "4.2 边界条件与载荷设置", 2)
    base.add_text(doc, "左边界施加完全固定约束，即 u=0、v=0；右边界施加沿 x 方向的均布拉力；上下边界自由。右边界总等效力为 q t H。该边界设置比理想均匀拉伸解更严格，因为固定端同时限制轴向位移和横向泊松收缩，会在左端附近引入局部二维应力扰动。")
    add_picture_fit(doc, figs["mesh"], "图 1 矩形方板三角形常应变单元网格划分", width_cm=7.25)
    add_picture_fit(doc, figs["bc"], "图 2 矩形方板边界条件与载荷示意图", width_cm=7.25)
    base.add_heading(doc, "4.3 网格划分与自由度编号", 2)
    base.add_text(doc, f"矩形区域采用三角形单元离散。每个节点有两个自由度，若节点编号为 n，则 x 与 y 方向自由度分别为 2n−1 和 2n。原始报告采用 2、4、8 个三角形单元进行网格敏感性比较；Abaqus 细网格结果包含 {mesh['node_count']} 个节点、{mesh['element_count']} 个 CPS3 单元和 {mesh['right_edge_node_count']} 个右边界加载节点。")
    base.add_heading(doc, "4.4 总体刚度矩阵组装与边界条件处理", 2)
    base.add_text(doc, "总体刚度矩阵由单元刚度矩阵按单元-节点连接关系累加得到。引入左边界位移约束后，自由自由度和固定自由度被分离。由于固定自由度位移为零，总体方程可简化为自由自由度子系统。")
    add_math_equation(doc, ["K d = F,   ", m_sub("d", "f"), " = ", m_subsup("K", "ff", "−1"), m_sub("F", "f")], 10)

    base.add_heading(doc, "5 MATLAB 数值实现", 1)
    base.add_heading(doc, "5.1 程序流程", 2)
    base.add_text(doc, "MATLAB 程序依次完成参数输入、本构矩阵建立、规则三角形网格生成、单元矩阵计算、总体刚度矩阵组装、右边界等效节点力构造、左边界位移约束施加、线性方程求解和后处理。后处理包括节点位移提取、单元应变与应力计算、单元结果向节点平均以及位移场、应力场和中线应力曲线绘制。")
    if figs["flow"].exists():
        add_picture_fit(doc, figs["flow"], "图 3 三角形常应变单元有限元分析 MATLAB 程序流程图", width_cm=7.25)
    base.add_heading(doc, "5.2 节点位移求解", 2)
    base.add_text(doc, "程序将左边界所有节点的两个位移自由度写入 fixed_dof，将其余自由度作为 free_dof。自由自由度位移由 K(free_dof,free_dof)d=F(free_dof) 求得，固定自由度位移保持为零。")
    base.add_heading(doc, "5.3 单元应变与应力计算", 2)
    add_math_equation(doc, [m_sub("ε", "e"), " = B", m_sub("d", "e")], 11)
    add_math_equation(doc, [m_sub("σ", "e"), " = D × ", m_sub("ε", "e"), " = D × B × ", m_sub("d", "e")], 12)
    base.add_text(doc, "由于 CST 单元内 B 为常量，单元内应变和应力均为常值。平滑应力云图来自单元结果向节点的平均，适合展示整体趋势；单元常值应力图则更能反映原始离散结果。")

    base.add_heading(doc, "6 结果与讨论", 1)
    base.add_heading(doc, "6.1 变形与位移响应", 2)
    base.add_text(doc, "变形图显示，矩形板在右端拉力作用下沿 x 方向整体伸长。x 方向位移从固定端到加载端逐渐增大，这是轴向应变沿板长方向累积的结果。左端位移被约束为零，右端承受拉力后产生最大轴向位移。")
    add_picture_fit(doc, figs["deform"], "图 4 矩形方板变形前后对比图", width_cm=7.25)
    base.add_text(doc, "y 方向位移体现泊松效应。板在 x 方向受拉时，材料倾向于沿 y 方向收缩；但左边界完全固定限制了横向位移，使固定端附近的横向收缩不能自由发展。因此，y 方向位移场不仅反映材料泊松比，也反映边界约束造成的局部变形抑制。")
    add_picture_fit(doc, figs["ux"], "图 5 x 方向位移场", width_cm=7.25)
    add_picture_fit(doc, figs["uy"], "图 6 y 方向位移场", width_cm=7.25)
    base.add_heading(doc, "6.2 应力场特征", 2)
    base.add_text(doc, f"理论均匀拉伸解给出 σx=q=100 MPa，σy=0，τxy=0。有限元结果中，板中部 σx 与理论拉应力接近，说明主要承载应力被合理捕捉。Abaqus 汇总结果显示，板中部平均 S11 为 {abaqus['S11_mid_avg_Pa']/1e6:.3f} MPa，相对误差约 {abaqus['S11_mid_error_percent']:.3f}%。")
    add_picture_fit(doc, figs["line"], "图 7 沿中线 σx 变化曲线", width_cm=7.25)
    base.add_text(doc, "σy 和 τxy 的非零值主要集中在固定端附近。其力学原因是左端完全固定限制了泊松收缩，使局部区域不再满足单向应力状态，而表现为二维约束应力状态。剪应力扰动则与固定端局部约束、三角形单元剖分方向和低阶离散误差有关。远离固定端后，σy 和 τxy 逐渐减小，σx 重新接近均匀拉伸状态。")
    add_picture_fit(doc, figs["s11"], "图 8 σx 平滑应力云图", width_cm=7.25)
    add_picture_fit(doc, figs["s22"], "图 9 σy 平滑应力云图", width_cm=7.25)
    add_picture_fit(doc, figs["s12"], "图 10 τxy 平滑剪应力云图", width_cm=7.25)
    add_picture_fit(doc, figs["const"], "图 11 σx 单元常值应力图", width_cm=7.25)

    base.add_heading(doc, "6.3 理论解与有限元解对比", 2)
    base.add_text(doc, "原始报告在 y=0 中线上选取 x=0.25 m、0.50 m 和 0.75 m 三个位置进行对比。这三个位置对应 1/4L、1/2L 和 3/4L，分别代表固定端影响区、板中部和加载端附近区域，同时避开 x=0 与 x=L 的边界节点。该选点方式既能展示沿板长方向的响应变化，又能减少边界节点奇异扰动对比较结果的影响。")
    doc.add_page_break()
    t2 = base.add_table(
        doc,
        "表 2 理论解与不同网格有限元结果对比",
        ["项目", "结果（x=0.25, 0.50, 0.75 m）"],
        compact_comparison_rows(),
        widths=[1700, 5000],
    )
    set_table_no_split(t2)
    base.add_text(doc, f"细网格结果进一步表明，右端平均 U1 为 {abaqus['U1_right_avg_m']:.6e} m，理论右端位移为 {theory['u_right_m']:.6e} m，相对误差约 {abaqus['U1_right_error_percent']:.3f}%。新增 R 科研图将该误差以沿程曲线和残差形式呈现，使整体精度与固定端刚化影响更加直观。")
    add_picture_fit(doc, figs["ra"], "图 12 x 方向位移有限元解与理论解对比及残差", width_cm=7.25)
    add_picture_fit(doc, figs["rb"], "图 13 沿板长方向的平均应力分量变化", width_cm=7.25)

    base.add_heading(doc, "6.4 科研图设计与误差解释", 2)
    base.add_text(doc, "新增科研图以定量验证和误差解释为核心，而不是重复展示已有云图。图 12 用节点位移与理论线性解对比，突出轴向位移的整体精度和固定端约束导致的轻微低估。图 13 汇总 σx、σy 和 τxy 随 x 位置的变化，强调 σx 在主体区域接近 100 MPa，同时 σy 和 τxy 的扰动主要发生在固定端附近。图 14 将关键误差来源与改进措施整理为定量-机制对应图，连接单元阶次、网格粗细、边界约束和结果偏差。")
    add_picture_fit(doc, figs["rc"], "图 14 主要误差来源及针对性改进措施", width_cm=7.25)
    doc.add_page_break()
    t3 = base.add_table(
        doc,
        "表 3 主要误差来源及影响分析",
        ["误差来源", "主要影响", "改进措施"],
        [
            ["CST 单元低阶近似", "单元内应力为常值，粗网格下应力分布呈块状", "加密网格或采用二次三角形单元"],
            ["固定端约束理想化", "限制泊松收缩，导致位移偏小并产生局部 σy、τxy", "采用更接近实际夹持条件的边界模型"],
            ["边界附近应力梯度", "固定端和加载端附近局部误差较大", "在边界与应力变化明显区域局部细化"],
            ["载荷离散化", "均布力转化为节点力后存在离散近似", "采用更细边界网格并保持虚功等效"],
        ],
        widths=[1600, 2500, 2100],
    )
    set_table_no_split(t3)


def add_back_matter(doc):
    base.add_heading(doc, "7 结论", 1)
    base.add_text(doc, "本文基于三角形常应变单元建立了矩形方板拉伸问题的平面应力有限元模型，并通过 MATLAB 程序完成了单元刚度计算、总体组装、边界条件处理、节点位移求解和应力后处理。结果与理论均匀拉伸解总体一致：x 方向位移沿加载方向逐渐增大，板中部 σx 接近 100 MPa，y 方向位移体现泊松效应。")
    base.add_text(doc, "有限元结果中 σy 和 τxy 的局部非零值并非计算错误，而是左端完全固定、网格离散和 CST 单元常应变近似共同作用的结果。该算例说明，有限元方法不仅可验证主体区域的理论解，也能揭示解析模型难以描述的边界扰动。后续精度提升应优先考虑边界区域局部细化和高阶单元，以降低低阶单元在高梯度应力区域的离散误差。")
    base.add_heading(doc, "参考文献", 1)
    for ref in [
        "[1] Zienkiewicz O C, Taylor R L, Zhu J Z. The Finite Element Method: Its Basis and Fundamentals. 7th ed. Oxford: Butterworth-Heinemann, 2013.",
        "[2] Bathe K J. Finite Element Procedures. Englewood Cliffs: Prentice Hall, 1996.",
        "[3] Cook R D, Malkus D S, Plesha M E, Witt R J. Concepts and Applications of Finite Element Analysis. 4th ed. New York: Wiley, 2001.",
        "[4] Timoshenko S P, Goodier J N. Theory of Elasticity. 3rd ed. New York: McGraw-Hill, 1970.",
        "[5] MATLAB Documentation. MATLAB: The Language of Technical Computing. MathWorks.",
    ]:
        base.add_text(doc, ref, first_line=False)
    base.add_heading(doc, "未发现的文件或未采用的资料", 1)
    base.add_text(doc, "未在源文件夹中发现独立 MATLAB .m 或 .mlx 文件；MATLAB 核心代码来自原始 Word 正文并已置于附录 A。", first_line=False)
    base.add_text(doc, "未直接嵌入 Abaqus ODB/CAE 二进制文件；其结果通过已导出的 CSV、JSON 和 PNG 图使用。", first_line=False)
    base.add_heading(doc, "附录 A MATLAB 核心代码", 1)
    for line in base.extract_code_from_source_docx().splitlines():
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        p.paragraph_format.line_spacing = 1.0
        r = p.add_run(line)
        base.set_run_font(r, size=7.5, name="Consolas", east="宋体")


def main():
    doc = init_doc()
    add_title_front(doc)
    add_main_text(doc)
    add_model_results(doc)
    add_back_matter(doc)
    doc.save(FINAL_DOCX)
    print(FINAL_DOCX)


if __name__ == "__main__":
    main()
