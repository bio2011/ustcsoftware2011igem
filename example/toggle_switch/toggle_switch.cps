<?xml version="1.0" encoding="UTF-8"?>
<!-- generated with COPASI 4.7 (Build 34) (http://www.copasi.org) at 2011-08-28 02:35:23 UTC -->
<?oxygen RNGSchema="http://www.copasi.org/static/schema/CopasiML.rng" type="xml"?>
<COPASI xmlns="http://www.copasi.org/static/schema" versionMajor="1" versionMinor="0" versionDevel="34">
  <ListOfFunctions>
    <Function key="Function_13" name="Mass action (irreversible)" type="MassAction" reversible="false">
      <Expression>
        k1*PRODUCT&lt;substrate_i&gt;
      </Expression>
      <ListOfParameterDescriptions>
        <ParameterDescription key="FunctionParameter_81" name="k1" order="0" role="constant"/>
        <ParameterDescription key="FunctionParameter_79" name="substrate" order="1" role="substrate"/>
      </ListOfParameterDescriptions>
    </Function>
    <Function key="Function_38" name="function_4_r1" type="UserDefined" reversible="false">
      <Expression>
        transp0_pout*s4
      </Expression>
      <ListOfParameterDescriptions>
        <ParameterDescription key="FunctionParameter_243" name="s4" order="0" role="modifier"/>
        <ParameterDescription key="FunctionParameter_246" name="transp0_pout" order="1" role="constant"/>
      </ListOfParameterDescriptions>
    </Function>
    <Function key="Function_44" name="function_4_r3" type="UserDefined" reversible="false">
      <Expression>
        transp0_pin*iptg
      </Expression>
      <ListOfParameterDescriptions>
        <ParameterDescription key="FunctionParameter_263" name="iptg" order="0" role="modifier"/>
        <ParameterDescription key="FunctionParameter_264" name="transp0_pin" order="1" role="constant"/>
      </ListOfParameterDescriptions>
    </Function>
    <Function key="Function_45" name="function_4_r5" type="UserDefined" reversible="false">
      <Expression>
        rule14_k*dna1
      </Expression>
      <ListOfParameterDescriptions>
        <ParameterDescription key="FunctionParameter_269" name="dna1" order="0" role="modifier"/>
        <ParameterDescription key="FunctionParameter_270" name="rule14_k" order="1" role="constant"/>
      </ListOfParameterDescriptions>
    </Function>
    <Function key="Function_46" name="function_4_r6" type="UserDefined" reversible="false">
      <Expression>
        rule13_k*dna2
      </Expression>
      <ListOfParameterDescriptions>
        <ParameterDescription key="FunctionParameter_273" name="dna2" order="0" role="modifier"/>
        <ParameterDescription key="FunctionParameter_274" name="rule13_k" order="1" role="constant"/>
      </ListOfParameterDescriptions>
    </Function>
    <Function key="Function_47" name="function_4_r7" type="UserDefined" reversible="false">
      <Expression>
        rule15_k*s5
      </Expression>
      <ListOfParameterDescriptions>
        <ParameterDescription key="FunctionParameter_277" name="rule15_k" order="0" role="constant"/>
        <ParameterDescription key="FunctionParameter_278" name="s5" order="1" role="modifier"/>
      </ListOfParameterDescriptions>
    </Function>
    <Function key="Function_48" name="function_4_r9" type="UserDefined" reversible="false">
      <Expression>
        rule15_k*s6
      </Expression>
      <ListOfParameterDescriptions>
        <ParameterDescription key="FunctionParameter_283" name="rule15_k" order="0" role="constant"/>
        <ParameterDescription key="FunctionParameter_284" name="s6" order="1" role="modifier"/>
      </ListOfParameterDescriptions>
    </Function>
    <Function key="Function_49" name="function_4_r12" type="UserDefined" reversible="false">
      <Expression>
        0.5*rule9_k*s7*s7
      </Expression>
      <ListOfParameterDescriptions>
        <ParameterDescription key="FunctionParameter_291" name="rule9_k" order="0" role="constant"/>
        <ParameterDescription key="FunctionParameter_292" name="s7" order="1" role="substrate"/>
      </ListOfParameterDescriptions>
    </Function>
    <Function key="Function_50" name="function_4_r14" type="UserDefined" reversible="false">
      <Expression>
        0.5*rule3_k*s8*s8
      </Expression>
      <ListOfParameterDescriptions>
        <ParameterDescription key="FunctionParameter_297" name="rule3_k" order="0" role="constant"/>
        <ParameterDescription key="FunctionParameter_298" name="s8" order="1" role="substrate"/>
      </ListOfParameterDescriptions>
    </Function>
    <Function key="Function_51" name="function_4_r18" type="UserDefined" reversible="false">
      <Expression>
        0.5*rule9_k*s9*s9
      </Expression>
      <ListOfParameterDescriptions>
        <ParameterDescription key="FunctionParameter_307" name="rule9_k" order="0" role="constant"/>
        <ParameterDescription key="FunctionParameter_308" name="s9" order="1" role="substrate"/>
      </ListOfParameterDescriptions>
    </Function>
    <Function key="Function_52" name="function_4_r20" type="UserDefined" reversible="false">
      <Expression>
        2*rule7_k*s10*s4
      </Expression>
      <ListOfParameterDescriptions>
        <ParameterDescription key="FunctionParameter_314" name="rule7_k" order="0" role="constant"/>
        <ParameterDescription key="FunctionParameter_315" name="s10" order="1" role="substrate"/>
        <ParameterDescription key="FunctionParameter_316" name="s4" order="2" role="substrate"/>
      </ListOfParameterDescriptions>
    </Function>
    <Function key="Function_53" name="function_4_r28" type="UserDefined" reversible="false">
      <Expression>
        2*rule8_k*s13
      </Expression>
      <ListOfParameterDescriptions>
        <ParameterDescription key="FunctionParameter_333" name="rule8_k" order="0" role="constant"/>
        <ParameterDescription key="FunctionParameter_334" name="s13" order="1" role="substrate"/>
      </ListOfParameterDescriptions>
    </Function>
    <Function key="Function_54" name="function_4_r30" type="UserDefined" reversible="false">
      <Expression>
        2*rule12_k*s14
      </Expression>
      <ListOfParameterDescriptions>
        <ParameterDescription key="FunctionParameter_339" name="rule12_k" order="0" role="constant"/>
        <ParameterDescription key="FunctionParameter_340" name="s14" order="1" role="substrate"/>
      </ListOfParameterDescriptions>
    </Function>
    <Function key="Function_55" name="function_4_r31" type="UserDefined" reversible="false">
      <Expression>
        2*rule6_k*s15
      </Expression>
      <ListOfParameterDescriptions>
        <ParameterDescription key="FunctionParameter_343" name="rule6_k" order="0" role="constant"/>
        <ParameterDescription key="FunctionParameter_344" name="s15" order="1" role="substrate"/>
      </ListOfParameterDescriptions>
    </Function>
  </ListOfFunctions>
  <Model key="Model_0" name="NoName" simulationType="time" timeUnit="s" volumeUnit="l" areaUnit="m²" lengthUnit="m" quantityUnit="mol" type="deterministic" avogadroConstant="6.02214179e+23">
    <MiriamAnnotation>
<rdf:RDF
   xmlns:dcterms="http://purl.org/dc/terms/"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <rdf:Description rdf:about="#Model_0">
    <dcterms:created>
      <rdf:Description>
        <dcterms:W3CDTF>2011-08-28T09:52:34Z</dcterms:W3CDTF>
      </rdf:Description>
    </dcterms:created>
  </rdf:Description>
</rdf:RDF>

    </MiriamAnnotation>
    <ListOfCompartments>
      <Compartment key="Compartment_0" name="Medium" simulationType="fixed" dimensionality="3">
      </Compartment>
      <Compartment key="Compartment_1" name="Ecoli" simulationType="fixed" dimensionality="3">
      </Compartment>
    </ListOfCompartments>
    <ListOfMetabolites>
      <Metabolite key="Metabolite_0" name="m:i0001(laci)" simulationType="reactions" compartment="Compartment_0">
      </Metabolite>
      <Metabolite key="Metabolite_1" name="d:b0014*()-c0012*(dim,dna,iptg)-b0034*(rib)-r0040*(tetr1,tetr2)" simulationType="reactions" compartment="Compartment_1">
      </Metabolite>
      <Metabolite key="Metabolite_2" name="d:b0014*()-c0040*(atc,dim,dna)-b0034*(rib)-r0010*(laci1,laci2)" simulationType="reactions" compartment="Compartment_1">
      </Metabolite>
      <Metabolite key="Metabolite_3" name="m:i0001(laci)" simulationType="reactions" compartment="Compartment_1">
      </Metabolite>
      <Metabolite key="Metabolite_4" name="r:b0034(rib)-c0012(dim,dna,iptg)" simulationType="reactions" compartment="Compartment_1">
      </Metabolite>
      <Metabolite key="Metabolite_5" name="r:b0034(rib)-c0040(atc,dim,dna)" simulationType="reactions" compartment="Compartment_1">
      </Metabolite>
      <Metabolite key="Metabolite_6" name="p:c0012(dim,dna,iptg)" simulationType="reactions" compartment="Compartment_1">
      </Metabolite>
      <Metabolite key="Metabolite_7" name="p:c0040(atc,dim,dna)" simulationType="reactions" compartment="Compartment_1">
      </Metabolite>
      <Metabolite key="Metabolite_8" name="m:i0001(laci!1).p:c0012(dim,dna,iptg!1)" simulationType="reactions" compartment="Compartment_1">
      </Metabolite>
      <Metabolite key="Metabolite_9" name="p:c0012(dim!1,dna,iptg).p:c0012(dim!1,dna,iptg)" simulationType="reactions" compartment="Compartment_1">
      </Metabolite>
      <Metabolite key="Metabolite_10" name="p:c0040(atc,dim!1,dna).p:c0040(atc,dim!1,dna)" simulationType="reactions" compartment="Compartment_1">
      </Metabolite>
      <Metabolite key="Metabolite_11" name="m:i0001(laci!1).p:c0012(dim!2,dna,iptg!1).p:c0012(dim!2,dna,iptg)" simulationType="reactions" compartment="Compartment_1">
      </Metabolite>
      <Metabolite key="Metabolite_12" name="m:i0001(laci!1).m:i0001(laci!2).p:c0012(dim!3,dna,iptg!1).p:c0012(dim!3,dna,iptg!2)" simulationType="reactions" compartment="Compartment_1">
      </Metabolite>
      <Metabolite key="Metabolite_13" name="d:b0014*()-c0040*(atc,dim,dna)-b0034*(rib)-r0010*(laci1!1,laci2!2).p:c0012(dim!3,dna!1,iptg).p:c0012(dim!3,dna!2,iptg)" simulationType="reactions" compartment="Compartment_1">
      </Metabolite>
      <Metabolite key="Metabolite_14" name="d:b0014*()-c0012*(dim,dna,iptg)-b0034*(rib)-r0040*(tetr1!1,tetr2!2).p:c0040(atc,dim!3,dna!1).p:c0040(atc,dim!3,dna!2)" simulationType="reactions" compartment="Compartment_1">
      </Metabolite>
    </ListOfMetabolites>
    <ListOfModelValues>
      <ModelValue key="ModelValue_0" name="NA" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_1" name="f" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_2" name="Ve" simulationType="assignment">
        <Expression>
          &lt;CN=Root,Model=NoName,Vector=Values[f],Reference=Value&gt;*0.4
        </Expression>
      </ModelValue>
      <ModelValue key="ModelValue_3" name="V" simulationType="assignment">
        <Expression>
          &lt;CN=Root,Model=NoName,Vector=Values[f],Reference=Value&gt;*7e-16
        </Expression>
      </ModelValue>
      <ModelValue key="ModelValue_4" name="N" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_5" name="iptg_init" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_6" name="dna1_init" simulationType="assignment">
        <Expression>
          1/&lt;CN=Root,Model=NoName,Vector=Values[NA],Reference=Value&gt;/&lt;CN=Root,Model=NoName,Vector=Values[V],Reference=Value&gt;
        </Expression>
      </ModelValue>
      <ModelValue key="ModelValue_7" name="dna2_init" simulationType="assignment">
        <Expression>
          1/&lt;CN=Root,Model=NoName,Vector=Values[NA],Reference=Value&gt;/&lt;CN=Root,Model=NoName,Vector=Values[V],Reference=Value&gt;
        </Expression>
      </ModelValue>
      <ModelValue key="ModelValue_8" name="pulse1_start" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_9" name="pulse1_conc" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_10" name="transp0_pout" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_11" name="transp0_pin" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_12" name="rule14_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_13" name="rule13_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_14" name="rule15_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_15" name="rule16_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_16" name="rule17_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_17" name="rule7_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_18" name="rule9_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_19" name="rule18_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_20" name="rule3_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_21" name="rule19_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_22" name="rule8_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_23" name="rule10_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_24" name="rule11_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_25" name="rule4_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_26" name="rule5_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_27" name="rule12_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_28" name="rule6_k" simulationType="fixed">
      </ModelValue>
      <ModelValue key="ModelValue_29" name="time" simulationType="assignment">
        <Expression>
          &lt;CN=Root,Model=NoName,Reference=Time&gt;
        </Expression>
      </ModelValue>
    </ListOfModelValues>
    <ListOfReactions>
      <Reaction key="Reaction_0" name="r1" reversible="false">
        <ListOfProducts>
          <Product metabolite="Metabolite_0" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfModifiers>
          <Modifier metabolite="Metabolite_3" stoichiometry="1"/>
        </ListOfModifiers>
        <ListOfConstants>
          <Constant key="Parameter_77" name="transp0_pout" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_38">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_243">
              <SourceParameter reference="Metabolite_3"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_246">
              <SourceParameter reference="ModelValue_10"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_1" name="r2" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_0" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfConstants>
          <Constant key="Parameter_76" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_11"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_0"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_2" name="r3" reversible="false">
        <ListOfProducts>
          <Product metabolite="Metabolite_3" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfModifiers>
          <Modifier metabolite="Metabolite_0" stoichiometry="1"/>
        </ListOfModifiers>
        <ListOfConstants>
          <Constant key="Parameter_75" name="transp0_pin" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_44">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_263">
              <SourceParameter reference="Metabolite_0"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_264">
              <SourceParameter reference="ModelValue_11"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_3" name="r4" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_3" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfConstants>
          <Constant key="Parameter_72" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_10"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_3"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_4" name="r5" reversible="false">
        <ListOfProducts>
          <Product metabolite="Metabolite_4" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfModifiers>
          <Modifier metabolite="Metabolite_1" stoichiometry="1"/>
        </ListOfModifiers>
        <ListOfConstants>
          <Constant key="Parameter_73" name="rule14_k" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_45">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_269">
              <SourceParameter reference="Metabolite_1"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_270">
              <SourceParameter reference="ModelValue_12"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_5" name="r6" reversible="false">
        <ListOfProducts>
          <Product metabolite="Metabolite_5" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfModifiers>
          <Modifier metabolite="Metabolite_2" stoichiometry="1"/>
        </ListOfModifiers>
        <ListOfConstants>
          <Constant key="Parameter_71" name="rule13_k" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_46">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_273">
              <SourceParameter reference="Metabolite_2"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_274">
              <SourceParameter reference="ModelValue_13"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_6" name="r7" reversible="false">
        <ListOfProducts>
          <Product metabolite="Metabolite_6" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfModifiers>
          <Modifier metabolite="Metabolite_4" stoichiometry="1"/>
        </ListOfModifiers>
        <ListOfConstants>
          <Constant key="Parameter_74" name="rule15_k" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_47">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_277">
              <SourceParameter reference="ModelValue_14"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_278">
              <SourceParameter reference="Metabolite_4"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_7" name="r8" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_4" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfConstants>
          <Constant key="Parameter_70" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_15"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_4"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_8" name="r9" reversible="false">
        <ListOfProducts>
          <Product metabolite="Metabolite_7" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfModifiers>
          <Modifier metabolite="Metabolite_5" stoichiometry="1"/>
        </ListOfModifiers>
        <ListOfConstants>
          <Constant key="Parameter_69" name="rule15_k" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_48">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_283">
              <SourceParameter reference="ModelValue_14"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_284">
              <SourceParameter reference="Metabolite_5"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_9" name="r10" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_5" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfConstants>
          <Constant key="Parameter_68" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_16"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_5"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_10" name="r11" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_6" stoichiometry="1"/>
          <Substrate metabolite="Metabolite_3" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_8" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_67" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_17"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_6"/>
              <SourceParameter reference="Metabolite_3"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_11" name="r12" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_6" stoichiometry="2"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_9" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_66" name="rule9_k" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_49">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_291">
              <SourceParameter reference="ModelValue_18"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_292">
              <SourceParameter reference="Metabolite_6"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_12" name="r13" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_6" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfConstants>
          <Constant key="Parameter_65" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_19"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_6"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_13" name="r14" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_7" stoichiometry="2"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_10" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_64" name="rule3_k" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_50">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_297">
              <SourceParameter reference="ModelValue_20"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_298">
              <SourceParameter reference="Metabolite_7"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_14" name="r15" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_7" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfConstants>
          <Constant key="Parameter_63" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_21"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_7"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_15" name="r16" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_8" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_3" stoichiometry="1"/>
          <Product metabolite="Metabolite_6" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_62" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_22"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_8"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_16" name="r17" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_6" stoichiometry="1"/>
          <Substrate metabolite="Metabolite_8" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_11" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_61" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_18"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_6"/>
              <SourceParameter reference="Metabolite_8"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_17" name="r18" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_8" stoichiometry="2"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_12" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_60" name="rule9_k" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_51">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_307">
              <SourceParameter reference="ModelValue_18"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_308">
              <SourceParameter reference="Metabolite_8"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_18" name="r19" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_8" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_3" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_59" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_19"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_8"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_19" name="r20" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_9" stoichiometry="1"/>
          <Substrate metabolite="Metabolite_3" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_11" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_58" name="rule7_k" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_52">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_314">
              <SourceParameter reference="ModelValue_17"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_315">
              <SourceParameter reference="Metabolite_9"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_316">
              <SourceParameter reference="Metabolite_3"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_20" name="r21" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_9" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_6" stoichiometry="2"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_57" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_23"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_9"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_21" name="r22" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_9" stoichiometry="1"/>
          <Substrate metabolite="Metabolite_2" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_13" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_56" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_24"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_9"/>
              <SourceParameter reference="Metabolite_2"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_22" name="r23" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_10" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_7" stoichiometry="2"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_55" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_25"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_10"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_23" name="r24" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_10" stoichiometry="1"/>
          <Substrate metabolite="Metabolite_1" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_14" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_52" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_26"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_10"/>
              <SourceParameter reference="Metabolite_1"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_24" name="r25" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_11" stoichiometry="1"/>
          <Substrate metabolite="Metabolite_3" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_12" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_53" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_17"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_11"/>
              <SourceParameter reference="Metabolite_3"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_25" name="r26" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_11" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_9" stoichiometry="1"/>
          <Product metabolite="Metabolite_3" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_54" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_22"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_11"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_26" name="r27" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_11" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_6" stoichiometry="1"/>
          <Product metabolite="Metabolite_8" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_51" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_23"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_11"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_27" name="r28" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_12" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_11" stoichiometry="1"/>
          <Product metabolite="Metabolite_3" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_50" name="rule8_k" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_53">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_333">
              <SourceParameter reference="ModelValue_22"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_334">
              <SourceParameter reference="Metabolite_12"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_28" name="r29" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_12" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_8" stoichiometry="2"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_47" name="k1" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_13">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_81">
              <SourceParameter reference="ModelValue_23"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_79">
              <SourceParameter reference="Metabolite_12"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_29" name="r30" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_13" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_2" stoichiometry="1"/>
          <Product metabolite="Metabolite_9" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_48" name="rule12_k" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_54">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_339">
              <SourceParameter reference="ModelValue_27"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_340">
              <SourceParameter reference="Metabolite_13"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
      <Reaction key="Reaction_30" name="r31" reversible="false">
        <ListOfSubstrates>
          <Substrate metabolite="Metabolite_14" stoichiometry="1"/>
        </ListOfSubstrates>
        <ListOfProducts>
          <Product metabolite="Metabolite_1" stoichiometry="1"/>
          <Product metabolite="Metabolite_10" stoichiometry="1"/>
        </ListOfProducts>
        <ListOfConstants>
          <Constant key="Parameter_49" name="rule6_k" value="1"/>
        </ListOfConstants>
        <KineticLaw function="Function_55">
          <ListOfCallParameters>
            <CallParameter functionParameter="FunctionParameter_343">
              <SourceParameter reference="ModelValue_28"/>
            </CallParameter>
            <CallParameter functionParameter="FunctionParameter_344">
              <SourceParameter reference="Metabolite_14"/>
            </CallParameter>
          </ListOfCallParameters>
        </KineticLaw>
      </Reaction>
    </ListOfReactions>
    <ListOfEvents>
      <Event key="Event_0" name="pulse1" order="1">
        <TriggerExpression>
          &lt;CN=Root,Model=NoName,Vector=Values[time],Reference=Value&gt; gt &lt;CN=Root,Model=NoName,Vector=Values[pulse1_start],Reference=Value&gt;
        </TriggerExpression>
        <ListOfAssignments>
          <Assignment targetKey="Metabolite_0">
            <Expression>
              &lt;CN=Root,Model=NoName,Vector=Values[pulse1_conc],Reference=Value&gt;
            </Expression>
          </Assignment>
        </ListOfAssignments>
      </Event>
    </ListOfEvents>
    <StateTemplate>
      <StateTemplateVariable objectReference="Model_0"/>
      <StateTemplateVariable objectReference="Metabolite_6"/>
      <StateTemplateVariable objectReference="Metabolite_8"/>
      <StateTemplateVariable objectReference="Metabolite_7"/>
      <StateTemplateVariable objectReference="Metabolite_3"/>
      <StateTemplateVariable objectReference="Metabolite_11"/>
      <StateTemplateVariable objectReference="Metabolite_9"/>
      <StateTemplateVariable objectReference="Metabolite_10"/>
      <StateTemplateVariable objectReference="Metabolite_5"/>
      <StateTemplateVariable objectReference="Metabolite_0"/>
      <StateTemplateVariable objectReference="Metabolite_4"/>
      <StateTemplateVariable objectReference="Metabolite_2"/>
      <StateTemplateVariable objectReference="Metabolite_1"/>
      <StateTemplateVariable objectReference="Metabolite_12"/>
      <StateTemplateVariable objectReference="Metabolite_13"/>
      <StateTemplateVariable objectReference="Metabolite_14"/>
      <StateTemplateVariable objectReference="ModelValue_2"/>
      <StateTemplateVariable objectReference="ModelValue_3"/>
      <StateTemplateVariable objectReference="ModelValue_6"/>
      <StateTemplateVariable objectReference="ModelValue_7"/>
      <StateTemplateVariable objectReference="ModelValue_29"/>
      <StateTemplateVariable objectReference="ModelValue_0"/>
      <StateTemplateVariable objectReference="ModelValue_1"/>
      <StateTemplateVariable objectReference="ModelValue_4"/>
      <StateTemplateVariable objectReference="ModelValue_5"/>
      <StateTemplateVariable objectReference="ModelValue_8"/>
      <StateTemplateVariable objectReference="ModelValue_9"/>
      <StateTemplateVariable objectReference="ModelValue_10"/>
      <StateTemplateVariable objectReference="ModelValue_11"/>
      <StateTemplateVariable objectReference="ModelValue_12"/>
      <StateTemplateVariable objectReference="ModelValue_13"/>
      <StateTemplateVariable objectReference="ModelValue_14"/>
      <StateTemplateVariable objectReference="ModelValue_15"/>
      <StateTemplateVariable objectReference="ModelValue_16"/>
      <StateTemplateVariable objectReference="ModelValue_17"/>
      <StateTemplateVariable objectReference="ModelValue_18"/>
      <StateTemplateVariable objectReference="ModelValue_19"/>
      <StateTemplateVariable objectReference="ModelValue_20"/>
      <StateTemplateVariable objectReference="ModelValue_21"/>
      <StateTemplateVariable objectReference="ModelValue_22"/>
      <StateTemplateVariable objectReference="ModelValue_23"/>
      <StateTemplateVariable objectReference="ModelValue_24"/>
      <StateTemplateVariable objectReference="ModelValue_25"/>
      <StateTemplateVariable objectReference="ModelValue_26"/>
      <StateTemplateVariable objectReference="ModelValue_27"/>
      <StateTemplateVariable objectReference="ModelValue_28"/>
      <StateTemplateVariable objectReference="Compartment_0"/>
      <StateTemplateVariable objectReference="Compartment_1"/>
    </StateTemplate>
    <InitialState type="initialState">
      0 0 0 0 0 0 0 0 0 0 0 1.000355779069765 1.000355779069765 0 0 0 0.4 7e-16 2.373042240151875e-09 2.373042240151875e-09 0 6.02e+23 1 100 0 40000 0.0001 0.1 0.1 0.5 0.5 0.01155 0.005783 0.005783 154000 12500000 0.00231 17900000 0.00231 0.2 10 20000000000 10 100000000 0.04 0.01 0.4 7e-16 
    </InitialState>
  </Model>
  <ListOfTasks>
    <Task key="Task_10" name="Steady-State" type="steadyState" scheduled="false" updateModel="false">
      <Report reference="Report_7" target="" append="1"/>
      <Problem>
        <Parameter name="JacobianRequested" type="bool" value="1"/>
        <Parameter name="StabilityAnalysisRequested" type="bool" value="1"/>
      </Problem>
      <Method name="Enhanced Newton" type="EnhancedNewton">
        <Parameter name="Resolution" type="unsignedFloat" value="1e-09"/>
        <Parameter name="Derivation Factor" type="unsignedFloat" value="0.001"/>
        <Parameter name="Use Newton" type="bool" value="1"/>
        <Parameter name="Use Integration" type="bool" value="1"/>
        <Parameter name="Use Back Integration" type="bool" value="1"/>
        <Parameter name="Accept Negative Concentrations" type="bool" value="0"/>
        <Parameter name="Iteration Limit" type="unsignedInteger" value="50"/>
        <Parameter name="Maximum duration for forward integration" type="unsignedFloat" value="1000000000"/>
        <Parameter name="Maximum duration for backward integration" type="unsignedFloat" value="1000000"/>
      </Method>
    </Task>
    <Task key="Task_9" name="Time-Course" type="timeCourse" scheduled="false" updateModel="false">
      <Problem>
        <Parameter name="StepNumber" type="unsignedInteger" value="1000"/>
        <Parameter name="StepSize" type="float" value="100"/>
        <Parameter name="Duration" type="float" value="100000"/>
        <Parameter name="TimeSeriesRequested" type="bool" value="1"/>
        <Parameter name="OutputStartTime" type="float" value="0"/>
        <Parameter name="Output Event" type="bool" value="0"/>
      </Problem>
      <Method name="Deterministic (LSODA)" type="Deterministic(LSODA)">
        <Parameter name="Integrate Reduced Model" type="bool" value="0"/>
        <Parameter name="Relative Tolerance" type="unsignedFloat" value="1e-06"/>
        <Parameter name="Absolute Tolerance" type="unsignedFloat" value="1e-12"/>
        <Parameter name="Max Internal Steps" type="unsignedInteger" value="10000"/>
      </Method>
    </Task>
    <Task key="Task_8" name="Scan" type="scan" scheduled="false" updateModel="false">
      <Problem>
        <Parameter name="Subtask" type="unsignedInteger" value="1"/>
        <ParameterGroup name="ScanItems">
        </ParameterGroup>
        <Parameter name="Output in subtask" type="bool" value="1"/>
        <Parameter name="Adjust initial conditions" type="bool" value="0"/>
      </Problem>
      <Method name="Scan Framework" type="ScanFramework">
      </Method>
    </Task>
    <Task key="Task_7" name="Elementary Flux Modes" type="fluxMode" scheduled="false" updateModel="false">
      <Report reference="Report_6" target="" append="1"/>
      <Problem>
      </Problem>
      <Method name="EFM Algorithm" type="EFMAlgorithm">
      </Method>
    </Task>
    <Task key="Task_6" name="Optimization" type="optimization" scheduled="false" updateModel="false">
      <Report reference="Report_5" target="" append="1"/>
      <Problem>
        <Parameter name="Subtask" type="cn" value="CN=Root,Vector=TaskList[Steady-State]"/>
        <ParameterText name="ObjectiveExpression" type="expression">
          
        </ParameterText>
        <Parameter name="Maximize" type="bool" value="0"/>
        <Parameter name="Randomize Start Values" type="bool" value="0"/>
        <Parameter name="Calculate Statistics" type="bool" value="1"/>
        <ParameterGroup name="OptimizationItemList">
        </ParameterGroup>
        <ParameterGroup name="OptimizationConstraintList">
        </ParameterGroup>
      </Problem>
      <Method name="Random Search" type="RandomSearch">
        <Parameter name="Number of Iterations" type="unsignedInteger" value="100000"/>
        <Parameter name="Random Number Generator" type="unsignedInteger" value="1"/>
        <Parameter name="Seed" type="unsignedInteger" value="0"/>
      </Method>
    </Task>
    <Task key="Task_5" name="Parameter Estimation" type="parameterFitting" scheduled="false" updateModel="false">
      <Report reference="Report_4" target="" append="1"/>
      <Problem>
        <Parameter name="Maximize" type="bool" value="0"/>
        <Parameter name="Randomize Start Values" type="bool" value="0"/>
        <Parameter name="Calculate Statistics" type="bool" value="1"/>
        <ParameterGroup name="OptimizationItemList">
        </ParameterGroup>
        <ParameterGroup name="OptimizationConstraintList">
        </ParameterGroup>
        <Parameter name="Steady-State" type="cn" value="CN=Root,Vector=TaskList[Steady-State]"/>
        <Parameter name="Time-Course" type="cn" value="CN=Root,Vector=TaskList[Time-Course]"/>
        <ParameterGroup name="Experiment Set">
        </ParameterGroup>
      </Problem>
      <Method name="Evolutionary Programming" type="EvolutionaryProgram">
        <Parameter name="Number of Generations" type="unsignedInteger" value="200"/>
        <Parameter name="Population Size" type="unsignedInteger" value="20"/>
        <Parameter name="Random Number Generator" type="unsignedInteger" value="1"/>
        <Parameter name="Seed" type="unsignedInteger" value="0"/>
      </Method>
    </Task>
    <Task key="Task_4" name="Metabolic Control Analysis" type="metabolicControlAnalysis" scheduled="false" updateModel="false">
      <Report reference="Report_3" target="" append="1"/>
      <Problem>
        <Parameter name="Steady-State" type="key" value="Task_10"/>
      </Problem>
      <Method name="MCA Method (Reder)" type="MCAMethod(Reder)">
        <Parameter name="Modulation Factor" type="unsignedFloat" value="1e-09"/>
      </Method>
    </Task>
    <Task key="Task_3" name="Lyapunov Exponents" type="lyapunovExponents" scheduled="false" updateModel="false">
      <Report reference="Report_2" target="" append="1"/>
      <Problem>
        <Parameter name="ExponentNumber" type="unsignedInteger" value="3"/>
        <Parameter name="DivergenceRequested" type="bool" value="1"/>
        <Parameter name="TransientTime" type="float" value="0"/>
      </Problem>
      <Method name="Wolf Method" type="WolfMethod">
        <Parameter name="Orthonormalization Interval" type="unsignedFloat" value="1"/>
        <Parameter name="Overall time" type="unsignedFloat" value="1000"/>
        <Parameter name="Relative Tolerance" type="unsignedFloat" value="1e-06"/>
        <Parameter name="Absolute Tolerance" type="unsignedFloat" value="1e-12"/>
        <Parameter name="Max Internal Steps" type="unsignedInteger" value="10000"/>
      </Method>
    </Task>
    <Task key="Task_2" name="Time Scale Separation Analysis" type="timeScaleSeparationAnalysis" scheduled="false" updateModel="false">
      <Report reference="Report_1" target="" append="1"/>
      <Problem>
        <Parameter name="StepNumber" type="unsignedInteger" value="100"/>
        <Parameter name="StepSize" type="float" value="0.01"/>
        <Parameter name="Duration" type="float" value="1"/>
        <Parameter name="TimeSeriesRequested" type="bool" value="1"/>
        <Parameter name="OutputStartTime" type="float" value="0"/>
      </Problem>
      <Method name="ILDM (LSODA,Deuflhard)" type="TimeScaleSeparation(ILDM,Deuflhard)">
        <Parameter name="Deuflhard Tolerance" type="unsignedFloat" value="1e-06"/>
      </Method>
    </Task>
    <Task key="Task_1" name="Sensitivities" type="sensitivities" scheduled="false" updateModel="false">
      <Report reference="Report_0" target="" append="1"/>
      <Problem>
        <Parameter name="SubtaskType" type="unsignedInteger" value="1"/>
        <ParameterGroup name="TargetFunctions">
          <Parameter name="SingleObject" type="cn" value=""/>
          <Parameter name="ObjectListType" type="unsignedInteger" value="7"/>
        </ParameterGroup>
        <ParameterGroup name="ListOfVariables">
          <ParameterGroup name="Variables">
            <Parameter name="SingleObject" type="cn" value=""/>
            <Parameter name="ObjectListType" type="unsignedInteger" value="41"/>
          </ParameterGroup>
        </ParameterGroup>
      </Problem>
      <Method name="Sensitivities Method" type="SensitivitiesMethod">
        <Parameter name="Delta factor" type="unsignedFloat" value="0.001"/>
        <Parameter name="Delta minimum" type="unsignedFloat" value="1e-12"/>
      </Method>
    </Task>
    <Task key="Task_11" name="Moieties" type="moieties" scheduled="false" updateModel="false">
      <Problem>
      </Problem>
      <Method name="Householder Reduction" type="Householder">
      </Method>
    </Task>
  </ListOfTasks>
  <ListOfReports>
    <Report key="Report_7" name="Steady-State" taskType="steadyState" separator="&#x09;" precision="6">
      <Comment>
        Automatically generated report.
      </Comment>
      <Footer>
        <Object cn="CN=Root,Vector=TaskList[Steady-State]"/>
      </Footer>
    </Report>
    <Report key="Report_6" name="Elementary Flux Modes" taskType="fluxMode" separator="&#x09;" precision="6">
      <Comment>
        Automatically generated report.
      </Comment>
      <Footer>
        <Object cn="CN=Root,Vector=TaskList[Elementary Flux Modes],Object=Result"/>
      </Footer>
    </Report>
    <Report key="Report_5" name="Optimization" taskType="optimization" separator="&#x09;" precision="6">
      <Comment>
        Automatically generated report.
      </Comment>
      <Header>
        <Object cn="CN=Root,Vector=TaskList[Optimization],Object=Description"/>
        <Object cn="String=\[Function Evaluations\]"/>
        <Object cn="Separator=&#x09;"/>
        <Object cn="String=\[Best Value\]"/>
        <Object cn="Separator=&#x09;"/>
        <Object cn="String=\[Best Parameters\]"/>
      </Header>
      <Body>
        <Object cn="CN=Root,Vector=TaskList[Optimization],Problem=Optimization,Reference=Function Evaluations"/>
        <Object cn="Separator=&#x09;"/>
        <Object cn="CN=Root,Vector=TaskList[Optimization],Problem=Optimization,Reference=Best Value"/>
        <Object cn="Separator=&#x09;"/>
        <Object cn="CN=Root,Vector=TaskList[Optimization],Problem=Optimization,Reference=Best Parameters"/>
      </Body>
      <Footer>
        <Object cn="String=&#x0a;"/>
        <Object cn="CN=Root,Vector=TaskList[Optimization],Object=Result"/>
      </Footer>
    </Report>
    <Report key="Report_4" name="Parameter Estimation" taskType="parameterFitting" separator="&#x09;" precision="6">
      <Comment>
        Automatically generated report.
      </Comment>
      <Header>
        <Object cn="CN=Root,Vector=TaskList[Parameter Estimation],Object=Description"/>
        <Object cn="String=\[Function Evaluations\]"/>
        <Object cn="Separator=&#x09;"/>
        <Object cn="String=\[Best Value\]"/>
        <Object cn="Separator=&#x09;"/>
        <Object cn="String=\[Best Parameters\]"/>
      </Header>
      <Body>
        <Object cn="CN=Root,Vector=TaskList[Parameter Estimation],Problem=Parameter Estimation,Reference=Function Evaluations"/>
        <Object cn="Separator=&#x09;"/>
        <Object cn="CN=Root,Vector=TaskList[Parameter Estimation],Problem=Parameter Estimation,Reference=Best Value"/>
        <Object cn="Separator=&#x09;"/>
        <Object cn="CN=Root,Vector=TaskList[Parameter Estimation],Problem=Parameter Estimation,Reference=Best Parameters"/>
      </Body>
      <Footer>
        <Object cn="String=&#x0a;"/>
        <Object cn="CN=Root,Vector=TaskList[Parameter Estimation],Object=Result"/>
      </Footer>
    </Report>
    <Report key="Report_3" name="Metabolic Control Analysis" taskType="metabolicControlAnalysis" separator="&#x09;" precision="6">
      <Comment>
        Automatically generated report.
      </Comment>
      <Header>
        <Object cn="CN=Root,Vector=TaskList[Metabolic Control Analysis],Object=Description"/>
      </Header>
      <Footer>
        <Object cn="String=&#x0a;"/>
        <Object cn="CN=Root,Vector=TaskList[Metabolic Control Analysis],Object=Result"/>
      </Footer>
    </Report>
    <Report key="Report_2" name="Lyapunov Exponents" taskType="lyapunovExponents" separator="&#x09;" precision="6">
      <Comment>
        Automatically generated report.
      </Comment>
      <Header>
        <Object cn="CN=Root,Vector=TaskList[Lyapunov Exponents],Object=Description"/>
      </Header>
      <Footer>
        <Object cn="String=&#x0a;"/>
        <Object cn="CN=Root,Vector=TaskList[Lyapunov Exponents],Object=Result"/>
      </Footer>
    </Report>
    <Report key="Report_1" name="Time Scale Separation Analysis" taskType="timeScaleSeparationAnalysis" separator="&#x09;" precision="6">
      <Comment>
        Automatically generated report.
      </Comment>
      <Header>
        <Object cn="CN=Root,Vector=TaskList[Time Scale Separation Analysis],Object=Description"/>
      </Header>
      <Footer>
        <Object cn="String=&#x0a;"/>
        <Object cn="CN=Root,Vector=TaskList[Time Scale Separation Analysis],Object=Result"/>
      </Footer>
    </Report>
    <Report key="Report_0" name="Sensitivities" taskType="sensitivities" separator="&#x09;" precision="6">
      <Comment>
        Automatically generated report.
      </Comment>
      <Header>
        <Object cn="CN=Root,Vector=TaskList[Sensitivities],Object=Description"/>
      </Header>
      <Footer>
        <Object cn="String=&#x0a;"/>
        <Object cn="CN=Root,Vector=TaskList[Sensitivities],Object=Result"/>
      </Footer>
    </Report>
  </ListOfReports>
  <ListOfPlots>
    <PlotSpecification name="Concentrations, Volumes, and Global Quantity Values" type="Plot2D" active="1">
      <Parameter name="log X" type="bool" value="0"/>
      <Parameter name="log Y" type="bool" value="0"/>
      <ListOfPlotItems>
        <PlotItem name="[m:i0001(laci){Medium}]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Compartments[Medium],Vector=Metabolites[m:i0001(laci)],Reference=Concentration"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="[d:b0014*()-c0012*(dim,dna,iptg)-b0034*(rib)-r0040*(tetr1,tetr2)]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Compartments[Ecoli],Vector=Metabolites[d:b0014*()-c0012*(dim\,dna\,iptg)-b0034*(rib)-r0040*(tetr1\,tetr2)],Reference=Concentration"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="[d:b0014*()-c0040*(atc,dim,dna)-b0034*(rib)-r0010*(laci1,laci2)]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Compartments[Ecoli],Vector=Metabolites[d:b0014*()-c0040*(atc\,dim\,dna)-b0034*(rib)-r0010*(laci1\,laci2)],Reference=Concentration"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="[m:i0001(laci){Ecoli}]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Compartments[Ecoli],Vector=Metabolites[m:i0001(laci)],Reference=Concentration"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="[r:b0034(rib)-c0012(dim,dna,iptg)]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Compartments[Ecoli],Vector=Metabolites[r:b0034(rib)-c0012(dim\,dna\,iptg)],Reference=Concentration"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="[r:b0034(rib)-c0040(atc,dim,dna)]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Compartments[Ecoli],Vector=Metabolites[r:b0034(rib)-c0040(atc\,dim\,dna)],Reference=Concentration"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="[p:c0012(dim,dna,iptg)]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Compartments[Ecoli],Vector=Metabolites[p:c0012(dim\,dna\,iptg)],Reference=Concentration"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="[p:c0040(atc,dim,dna)]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Compartments[Ecoli],Vector=Metabolites[p:c0040(atc\,dim\,dna)],Reference=Concentration"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="[m:i0001(laci!1).p:c0012(dim,dna,iptg!1)]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Compartments[Ecoli],Vector=Metabolites[m:i0001(laci!1).p:c0012(dim\,dna\,iptg!1)],Reference=Concentration"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="[p:c0012(dim!1,dna,iptg).p:c0012(dim!1,dna,iptg)]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Compartments[Ecoli],Vector=Metabolites[p:c0012(dim!1\,dna\,iptg).p:c0012(dim!1\,dna\,iptg)],Reference=Concentration"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="[p:c0040(atc,dim!1,dna).p:c0040(atc,dim!1,dna)]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Compartments[Ecoli],Vector=Metabolites[p:c0040(atc\,dim!1\,dna).p:c0040(atc\,dim!1\,dna)],Reference=Concentration"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="[m:i0001(laci!1).p:c0012(dim!2,dna,iptg!1).p:c0012(dim!2,dna,iptg)]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Compartments[Ecoli],Vector=Metabolites[m:i0001(laci!1).p:c0012(dim!2\,dna\,iptg!1).p:c0012(dim!2\,dna\,iptg)],Reference=Concentration"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="[m:i0001(laci!1).m:i0001(laci!2).p:c0012(dim!3,dna,iptg!1).p:c0012(dim!3,dna,iptg!2)]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Compartments[Ecoli],Vector=Metabolites[m:i0001(laci!1).m:i0001(laci!2).p:c0012(dim!3\,dna\,iptg!1).p:c0012(dim!3\,dna\,iptg!2)],Reference=Concentration"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="[d:b0014*()-c0040*(atc,dim,dna)-b0034*(rib)-r0010*(laci1!1,laci2!2).p:c0012(dim!3,dna!1,iptg).p:c0012(dim!3,dna!2,iptg)]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Compartments[Ecoli],Vector=Metabolites[d:b0014*()-c0040*(atc\,dim\,dna)-b0034*(rib)-r0010*(laci1!1\,laci2!2).p:c0012(dim!3\,dna!1\,iptg).p:c0012(dim!3\,dna!2\,iptg)],Reference=Concentration"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="[d:b0014*()-c0012*(dim,dna,iptg)-b0034*(rib)-r0040*(tetr1!1,tetr2!2).p:c0040(atc,dim!3,dna!1).p:c0040(atc,dim!3,dna!2)]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Compartments[Ecoli],Vector=Metabolites[d:b0014*()-c0012*(dim\,dna\,iptg)-b0034*(rib)-r0040*(tetr1!1\,tetr2!2).p:c0040(atc\,dim!3\,dna!1).p:c0040(atc\,dim!3\,dna!2)],Reference=Concentration"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="Values[Ve]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Values[Ve],Reference=Value"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="Values[V]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Values[V],Reference=Value"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="Values[dna1_init]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Values[dna1_init],Reference=Value"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="Values[dna2_init]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Values[dna2_init],Reference=Value"/>
          </ListOfChannels>
        </PlotItem>
        <PlotItem name="Values[time]" type="Curve2D">
          <Parameter name="Line type" type="unsignedInteger" value="0"/>
          <Parameter name="Recording Activity" type="string" value="during"/>
          <ListOfChannels>
            <ChannelSpec cn="CN=Root,Model=NoName,Reference=Time"/>
            <ChannelSpec cn="CN=Root,Model=NoName,Vector=Values[time],Reference=Value"/>
          </ListOfChannels>
        </PlotItem>
      </ListOfPlotItems>
    </PlotSpecification>
  </ListOfPlots>
  <GUI>
  </GUI>
  <SBMLReference file="toggle_switch.xml">
    <SBMLMap SBMLid="Ecoli" COPASIkey="Compartment_1"/>
    <SBMLMap SBMLid="Medium" COPASIkey="Compartment_0"/>
    <SBMLMap SBMLid="N" COPASIkey="ModelValue_4"/>
    <SBMLMap SBMLid="NA" COPASIkey="ModelValue_0"/>
    <SBMLMap SBMLid="V" COPASIkey="ModelValue_3"/>
    <SBMLMap SBMLid="Ve" COPASIkey="ModelValue_2"/>
    <SBMLMap SBMLid="dna1" COPASIkey="Metabolite_1"/>
    <SBMLMap SBMLid="dna1_init" COPASIkey="ModelValue_6"/>
    <SBMLMap SBMLid="dna2" COPASIkey="Metabolite_2"/>
    <SBMLMap SBMLid="dna2_init" COPASIkey="ModelValue_7"/>
    <SBMLMap SBMLid="f" COPASIkey="ModelValue_1"/>
    <SBMLMap SBMLid="iptg" COPASIkey="Metabolite_0"/>
    <SBMLMap SBMLid="iptg_init" COPASIkey="ModelValue_5"/>
    <SBMLMap SBMLid="pulse1" COPASIkey="Event_0"/>
    <SBMLMap SBMLid="pulse1_conc" COPASIkey="ModelValue_9"/>
    <SBMLMap SBMLid="pulse1_start" COPASIkey="ModelValue_8"/>
    <SBMLMap SBMLid="r1" COPASIkey="Reaction_0"/>
    <SBMLMap SBMLid="r10" COPASIkey="Reaction_9"/>
    <SBMLMap SBMLid="r11" COPASIkey="Reaction_10"/>
    <SBMLMap SBMLid="r12" COPASIkey="Reaction_11"/>
    <SBMLMap SBMLid="r13" COPASIkey="Reaction_12"/>
    <SBMLMap SBMLid="r14" COPASIkey="Reaction_13"/>
    <SBMLMap SBMLid="r15" COPASIkey="Reaction_14"/>
    <SBMLMap SBMLid="r16" COPASIkey="Reaction_15"/>
    <SBMLMap SBMLid="r17" COPASIkey="Reaction_16"/>
    <SBMLMap SBMLid="r18" COPASIkey="Reaction_17"/>
    <SBMLMap SBMLid="r19" COPASIkey="Reaction_18"/>
    <SBMLMap SBMLid="r2" COPASIkey="Reaction_1"/>
    <SBMLMap SBMLid="r20" COPASIkey="Reaction_19"/>
    <SBMLMap SBMLid="r21" COPASIkey="Reaction_20"/>
    <SBMLMap SBMLid="r22" COPASIkey="Reaction_21"/>
    <SBMLMap SBMLid="r23" COPASIkey="Reaction_22"/>
    <SBMLMap SBMLid="r24" COPASIkey="Reaction_23"/>
    <SBMLMap SBMLid="r25" COPASIkey="Reaction_24"/>
    <SBMLMap SBMLid="r26" COPASIkey="Reaction_25"/>
    <SBMLMap SBMLid="r27" COPASIkey="Reaction_26"/>
    <SBMLMap SBMLid="r28" COPASIkey="Reaction_27"/>
    <SBMLMap SBMLid="r29" COPASIkey="Reaction_28"/>
    <SBMLMap SBMLid="r3" COPASIkey="Reaction_2"/>
    <SBMLMap SBMLid="r30" COPASIkey="Reaction_29"/>
    <SBMLMap SBMLid="r31" COPASIkey="Reaction_30"/>
    <SBMLMap SBMLid="r4" COPASIkey="Reaction_3"/>
    <SBMLMap SBMLid="r5" COPASIkey="Reaction_4"/>
    <SBMLMap SBMLid="r6" COPASIkey="Reaction_5"/>
    <SBMLMap SBMLid="r7" COPASIkey="Reaction_6"/>
    <SBMLMap SBMLid="r8" COPASIkey="Reaction_7"/>
    <SBMLMap SBMLid="r9" COPASIkey="Reaction_8"/>
    <SBMLMap SBMLid="rule10_k" COPASIkey="ModelValue_23"/>
    <SBMLMap SBMLid="rule11_k" COPASIkey="ModelValue_24"/>
    <SBMLMap SBMLid="rule12_k" COPASIkey="ModelValue_27"/>
    <SBMLMap SBMLid="rule13_k" COPASIkey="ModelValue_13"/>
    <SBMLMap SBMLid="rule14_k" COPASIkey="ModelValue_12"/>
    <SBMLMap SBMLid="rule15_k" COPASIkey="ModelValue_14"/>
    <SBMLMap SBMLid="rule16_k" COPASIkey="ModelValue_15"/>
    <SBMLMap SBMLid="rule17_k" COPASIkey="ModelValue_16"/>
    <SBMLMap SBMLid="rule18_k" COPASIkey="ModelValue_19"/>
    <SBMLMap SBMLid="rule19_k" COPASIkey="ModelValue_21"/>
    <SBMLMap SBMLid="rule3_k" COPASIkey="ModelValue_20"/>
    <SBMLMap SBMLid="rule4_k" COPASIkey="ModelValue_25"/>
    <SBMLMap SBMLid="rule5_k" COPASIkey="ModelValue_26"/>
    <SBMLMap SBMLid="rule6_k" COPASIkey="ModelValue_28"/>
    <SBMLMap SBMLid="rule7_k" COPASIkey="ModelValue_17"/>
    <SBMLMap SBMLid="rule8_k" COPASIkey="ModelValue_22"/>
    <SBMLMap SBMLid="rule9_k" COPASIkey="ModelValue_18"/>
    <SBMLMap SBMLid="s10" COPASIkey="Metabolite_9"/>
    <SBMLMap SBMLid="s11" COPASIkey="Metabolite_10"/>
    <SBMLMap SBMLid="s12" COPASIkey="Metabolite_11"/>
    <SBMLMap SBMLid="s13" COPASIkey="Metabolite_12"/>
    <SBMLMap SBMLid="s14" COPASIkey="Metabolite_13"/>
    <SBMLMap SBMLid="s15" COPASIkey="Metabolite_14"/>
    <SBMLMap SBMLid="s4" COPASIkey="Metabolite_3"/>
    <SBMLMap SBMLid="s5" COPASIkey="Metabolite_4"/>
    <SBMLMap SBMLid="s6" COPASIkey="Metabolite_5"/>
    <SBMLMap SBMLid="s7" COPASIkey="Metabolite_6"/>
    <SBMLMap SBMLid="s8" COPASIkey="Metabolite_7"/>
    <SBMLMap SBMLid="s9" COPASIkey="Metabolite_8"/>
    <SBMLMap SBMLid="time" COPASIkey="ModelValue_29"/>
    <SBMLMap SBMLid="transp0_pin" COPASIkey="ModelValue_11"/>
    <SBMLMap SBMLid="transp0_pout" COPASIkey="ModelValue_10"/>
  </SBMLReference>
</COPASI>
