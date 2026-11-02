import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navMyReturn => 'Mi declaración';

  @override
  String get navAssistant => 'Asistente IA';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get refundEstimate => 'Reembolso';

  @override
  String get oweEstimate => 'Por pagar';

  @override
  String get topicsHeader => 'Completemos su declaración';

  @override
  String get topicsSubheader => 'Avance por cada tema. Puede saltar cuando quiera: sus respuestas se guardan automáticamente.';

  @override
  String issuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puntos necesitan atención',
      one: '1 punto necesita atención',
    );
    return '$_temp0';
  }

  @override
  String issuesFoundInfo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sugerencias para revisar',
      one: '1 sugerencia para revisar',
    );
    return '$_temp0';
  }

  @override
  String get continueToReview => 'Continuar a la revisión';

  @override
  String get jumpToResults => 'Ver mi cálculo';

  @override
  String autosaveNote(String name) {
    return 'Guardado automáticamente en $name';
  }

  @override
  String get whyWeAsk => '¿Por qué lo preguntamos?';

  @override
  String topicStep(int a, int b) {
    return 'Paso $a de $b';
  }

  @override
  String get back => 'Atrás';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get seeResults => 'Ver mis resultados';

  @override
  String get topicPersonal => 'Datos personales';

  @override
  String get topicIncome => 'Ingresos';

  @override
  String get topicDeductions => 'Deducciones y ajustes';

  @override
  String get topicCredits => 'Créditos y pagos';

  @override
  String get pagePersonalInfo => 'Cuéntenos sobre usted';

  @override
  String get pageSpouse => 'Su cónyuge';

  @override
  String get pageDependents => 'Dependientes';

  @override
  String get pageW2 => 'Salarios W-2';

  @override
  String get pageInterest => 'Ingresos por intereses';

  @override
  String get pageDividends => 'Dividendos';

  @override
  String get pageCapGains => 'Ventas de inversiones';

  @override
  String get pageSelfEmployment => 'Trabajo por cuenta propia';

  @override
  String get pageRetirement => 'Distribuciones de jubilación';

  @override
  String get pageOtherIncome => 'Otros ingresos';

  @override
  String get pageDeductions => 'Deducciones';

  @override
  String get pageCredits => 'Créditos';

  @override
  String get secYourInfo => 'Su información';

  @override
  String get secFilingStatus => 'Estado civil tributario';

  @override
  String get secSpouseInfo => 'Información del cónyuge';

  @override
  String get secSocialSecurity => 'Beneficios del Seguro Social';

  @override
  String get secUnemployment => 'Compensación por desempleo';

  @override
  String get secOtherIncome => 'Otros ingresos';

  @override
  String get secObbba => 'Deducciones especiales 2025';

  @override
  String get secItemized => 'Deducciones detalladas (opcional)';

  @override
  String get secAdjustments => 'Ajustes al ingreso';

  @override
  String get secChildCare => 'Cuidado de niños y dependientes';

  @override
  String get secEducation => 'Gastos educativos';

  @override
  String get secSavers => 'Aportaciones de ahorro para el retiro';

  @override
  String get secPayments => 'Pagos ya realizados';

  @override
  String get fFirstName => 'Nombre';

  @override
  String get fLastName => 'Apellido';

  @override
  String get fSsn => 'Número de Seguro Social';

  @override
  String get fDateOfBirth => 'Fecha de nacimiento';

  @override
  String get fBlind => 'Legalmente ciego(a)';

  @override
  String get fFilingStatus => 'Estado civil tributario';

  @override
  String get fSsBenefits => 'Total de beneficios del Seguro Social recibidos';

  @override
  String get fUnemployment => 'Compensación por desempleo recibida';

  @override
  String get fUnemploymentWithheld => 'Impuesto federal retenido del desempleo';

  @override
  String get fOtherIncomeDesc => 'Descripción (ej. premio, jurado)';

  @override
  String get hOtherIncome => 'Breve descripción del ingreso';

  @override
  String get fOtherIncomeAmount => 'Monto';

  @override
  String get fCarLoanInterest => 'Intereses calificados de préstamo de auto (2025–2028)';

  @override
  String get fMedical => 'Gastos médicos y dentales';

  @override
  String get fSalt => 'Impuestos estatales y locales pagados (ingresos + propiedad)';

  @override
  String get fMortgage => 'Intereses hipotecarios (Formulario 1098)';

  @override
  String get fCharityCash => 'Donaciones caritativas (efectivo)';

  @override
  String get fCharityNonCash => 'Donaciones caritativas (bienes)';

  @override
  String get fIra => 'Aportaciones a IRA tradicional';

  @override
  String get fStudentLoanInterest => 'Intereses de préstamos estudiantiles (Formulario 1098-E)';

  @override
  String get fHsa => 'Aportaciones a HSA';

  @override
  String get fEducator => 'Gastos de educadores';

  @override
  String get fChildCare => 'Gastos de cuidado infantil (para poder trabajar o buscar trabajo)';

  @override
  String get fAotc => 'Gastos calificados para el crédito americano AOTC (máx. 4,000)';

  @override
  String get fLlc => 'Gastos calificados de aprendizaje continuo (máx. 10,000)';

  @override
  String get fSavers => 'Aportaciones de retiro para el Crédito del Ahorrador';

  @override
  String get fEstimatedPayments => 'Pagos de impuestos estimados de este año';

  @override
  String get infoYourName => 'Ingrese su nombre legal exactamente como aparece en su tarjeta del Seguro Social.';

  @override
  String get infoSsn => 'Su SSN se guarda solo en este dispositivo. Nunca sale de su equipo salvo que usted exporte un archivo.';

  @override
  String get infoDob => 'Su edad afecta deducciones adicionales para mayores de 65 y las reglas de edad del EITC.';

  @override
  String get infoPersonal => 'Estos datos aparecen en su declaración. Puede editarlos cuando quiera.';

  @override
  String get infoSpouse => 'Necesario para casados que declaran juntos o por separado.';

  @override
  String get infoDependents => 'Un dependiente es un hijo o pariente que usted sostiene. Puede habilitar el Crédito por Hijos, el EITC o beneficios educativos.';

  @override
  String get infoW2 => 'Copie los números directamente de las casillas de su W-2. La casilla 1 son sus salarios gravables.';

  @override
  String get infoInterest => 'Del Formulario 1099-INT: casilla 1 son intereses gravables, casilla 8 son exentos (ej. bonos municipales).';

  @override
  String get infoDividends => 'Del Formulario 1099-DIV: casilla 1a dividendos ordinarios, casilla 1b calificados (tasa menor).';

  @override
  String get infoCapGains => 'Cada venta del 1099-B de su corredor: precio de venta y costo base. Más de un año = largo plazo (tasas menores).';

  @override
  String get infoSe => 'Su utilidad neta (ingresos menos gastos) de trabajo independiente. Calculamos el impuesto SE por usted.';

  @override
  String get infoRetirement => 'Del Formulario 1099-R: el monto gravable suele estar en la casilla 2a.';

  @override
  String get infoSs => 'Está en la casilla 3 de su SSA-1099. Solo una parte puede ser gravable: nosotros lo calculamos.';

  @override
  String get infoCarLoan => 'Nuevo en 2025: intereses de préstamo de un vehículo personal (de su financiera). Se reduce con ingresos altos.';

  @override
  String get infoOtherIncome => 'Ingresos únicos o inusuales. Las ganancias de apuestas requieren atención especial: consulte a un profesional.';

  @override
  String get infoMedical => 'Solo cuenta la parte que excede el 7.5% de su ingreso. Incluya primas que pagó usted.';

  @override
  String get infoSalt => 'Impuestos estatales/locales de ingresos + propiedad. El límite es \$10,000 (2024) o \$40,000 (2025, se reduce con ingresos altos).';

  @override
  String get infoIra => 'Las aportaciones a IRA tradicional pueden ser deducibles según su ingreso y plan laboral.';

  @override
  String get infoSli => 'Hasta \$2,500 de intereses de préstamos estudiantiles, con reducción gradual.';

  @override
  String get infoDeductions => 'Comparamos automáticamente detalladas vs estándar y usamos la que más le convenga.';

  @override
  String get infoChildCare => 'Pagos para poder trabajar o buscar trabajo. Máx. \$3,000 por un niño, \$6,000 por dos o más.';

  @override
  String get infoAotc => 'Primeros cuatro años universitarios. Gastos calificados como matrícula y libros (máx. \$4,000).';

  @override
  String get infoLlc => 'Cualquier nivel de estudio: matrícula y cuotas (máx. \$10,000, el crédito es 20%).';

  @override
  String get infoSavers => 'Aportaciones a IRA o plan laboral pueden devolver hasta 50% como crédito si su ingreso es bajo o moderado.';

  @override
  String get infoCredits => 'Pagos y créditos reducen lo que debe. Algunos créditos son reembolsables: pueden aumentar su reembolso.';

  @override
  String get emptyW2 => 'Aún no hay W-2. Agregue uno por cada empleador.';

  @override
  String get addW2 => 'Agregar un W-2';

  @override
  String w2N(int n) {
    return 'W-2 #$n';
  }

  @override
  String get fEmployer => 'Nombre del empleador';

  @override
  String get fEin => 'Número de identificación del empleador (EIN)';

  @override
  String get fWagesBox1 => 'Salarios (casilla 1)';

  @override
  String get fFedWithheldBox2 => 'Impuesto federal retenido (casilla 2)';

  @override
  String get fSsWagesBox3 => 'Salarios del Seguro Social (casilla 3)';

  @override
  String get fSsWithheldBox4 => 'Impuesto del Seguro Social retenido (casilla 4)';

  @override
  String get fMedicareBox6 => 'Impuesto de Medicare retenido (casilla 6)';

  @override
  String get fQualifiedTips => 'Propinas calificadas (2025)';

  @override
  String get fQualifiedOvertime => 'Horas extra calificadas (2025)';

  @override
  String get emptyDependents => 'Aún no hay dependientes.';

  @override
  String get addDependent => 'Agregar dependiente';

  @override
  String dependentN(int n) {
    return 'Dependiente #$n';
  }

  @override
  String get fRelationship => 'Parentesco (hijo, hija, madre…)';

  @override
  String get fFullTimeStudent => 'Estudiante de tiempo completo';

  @override
  String get fPermanentlyDisabled => 'Total y permanentemente incapacitado(a)';

  @override
  String get emptyInterest => 'Aún no hay intereses.';

  @override
  String get addPayer => 'Agregar pagador';

  @override
  String payerN(int n) {
    return 'Pagador #$n';
  }

  @override
  String get fPayer => 'Nombre del pagador';

  @override
  String get fTaxableInterest => 'Intereses gravables (1099-INT casilla 1)';

  @override
  String get fTaxExemptInterest => 'Intereses exentos (casilla 8)';

  @override
  String get emptyDividends => 'Aún no hay dividendos.';

  @override
  String get fOrdinaryDividends => 'Dividendos ordinarios (casilla 1a)';

  @override
  String get fQualifiedDividends => 'Dividendos calificados (casilla 1b)';

  @override
  String get emptyCapGains => 'Aún no hay ventas.';

  @override
  String get addSale => 'Agregar venta';

  @override
  String saleN(int n) {
    return 'Venta #$n';
  }

  @override
  String get fDescription => 'Descripción (ej. acciones AAPL)';

  @override
  String get fProceeds => 'Precio de venta';

  @override
  String get fCostBasis => 'Costo base (lo que pagó)';

  @override
  String get fLongTerm => 'Poseído más de un año (largo plazo)';

  @override
  String get emptySe => 'Aún no hay negocios.';

  @override
  String get addBusiness => 'Agregar negocio';

  @override
  String businessN(int n) {
    return 'Negocio #$n';
  }

  @override
  String get fBusinessName => 'Nombre del negocio';

  @override
  String get fNetProfit => 'Utilidad neta (ingresos menos gastos)';

  @override
  String get fSeTips => 'Propinas calificadas (2025)';

  @override
  String get fSeHealthPremiums => 'Primas de seguro médico de trabajador independiente';

  @override
  String get fSepSimple => 'Aportaciones a plan SEP/SIMPle';

  @override
  String get emptyRetirement => 'Aún no hay distribuciones.';

  @override
  String get fGrossDistribution => 'Distribución bruta (casilla 1)';

  @override
  String get fTaxableAmount => 'Monto gravable (casilla 2a)';

  @override
  String get fFedWithheld => 'Impuesto federal retenido (casilla 4)';

  @override
  String get reviewTitle => 'Revise sus respuestas';

  @override
  String get rowWages => 'Salarios';

  @override
  String get rowSeIncome => 'Ingresos por cuenta propia';

  @override
  String get rowInterest => 'Intereses';

  @override
  String get rowDividends => 'Dividendos';

  @override
  String get rowCapGains => 'Ganancia de capital neta';

  @override
  String get rowRetirement => 'Jubilación (gravable)';

  @override
  String get rowSs => 'Seguro Social (gravable)';

  @override
  String get rowUnemployment => 'Desempleo';

  @override
  String get rowOther => 'Otros ingresos';

  @override
  String get rowTotalIncome => 'Ingresos totales';

  @override
  String get rowAgi => 'Ingreso bruto ajustado (AGI)';

  @override
  String get rowItemized => 'Deducciones detalladas';

  @override
  String get rowStandard => 'Deducción estándar';

  @override
  String get rowQbi => 'Deducción QBI (§199A)';

  @override
  String get rowSenior => 'Deducción para adultos mayores';

  @override
  String get rowTaxableIncome => 'Ingreso gravable';

  @override
  String get rowTax => 'Impuesto';

  @override
  String get rowSeTax => 'Impuesto sobre trabajo independiente';

  @override
  String get rowCtc => 'Crédito por Hijos';

  @override
  String get rowCare => 'Crédito por cuidado de niños y dependientes';

  @override
  String get rowAotc => 'Crédito americano AOTC';

  @override
  String get rowLlc => 'Crédito de aprendizaje continuo';

  @override
  String get rowSavers => 'Crédito del Ahorrador';

  @override
  String get rowEitc => 'Crédito por Ingreso del Trabajo (EITC)';

  @override
  String get rowPayments => 'Retenciones y pagos estimados';

  @override
  String get editAnswers => 'Editar mis respuestas';

  @override
  String get issueMissingSpouse => 'Este estado civil requiere cónyuge: agréguelo en Datos personales.';

  @override
  String get issueMfsLimits => 'Casado(a) declarando por separado no puede reclamar EITC, créditos educativos ni la deducción para adultos mayores.';

  @override
  String get issueMissingSsn => 'Falta su SSN: agréguelo en Datos personales.';

  @override
  String get issueDependentSsn => 'Un dependiente no tiene SSN, necesario para la mayoría de los créditos.';

  @override
  String get issueDependentDob => 'Falta la fecha de nacimiento de un dependiente; no se pueden verificar reglas de edad.';

  @override
  String get issueW2Employer => 'Un W-2 no tiene nombre del empleador.';

  @override
  String get issueW2NoWithholding => 'Un W-2 no muestra retención federal: revise la casilla 2.';

  @override
  String get issueSeTax => 'Ingresos por cuenta propia superiores a \$400 generan impuesto SE: quizá necesite pagos estimados trimestrales.';

  @override
  String get issueObbbaOnly2025 => 'Las deducciones de propinas y horas extra aplican solo a 2025–2028.';

  @override
  String get resultsTitle => 'Su cálculo';

  @override
  String get refundHeadline => 'Reembolso estimado';

  @override
  String get oweHeadline => 'Saldo estimado por pagar';

  @override
  String get estimateDisclaimer => 'Este es un cálculo de planeación de Nitro Nissi: no es una declaración presentada ni asesoría fiscal.';

  @override
  String get bracketBreakdown => 'Cómo se forma su impuesto';

  @override
  String preferentialNote(String amount, String tax) {
    return 'Incluye $amount con tasas preferenciales de 0/15/20% (ahorra $tax).';
  }

  @override
  String get factAgi => 'Ingreso bruto ajustado';

  @override
  String get factDeduction => 'Deducción aplicada';

  @override
  String get factTaxable => 'Ingreso gravable';

  @override
  String get factEffective => 'Tasa efectiva';

  @override
  String get factMarginal => 'Tasa marginal máxima';

  @override
  String get factCredits => 'Créditos totales';

  @override
  String get factOtherTaxes => 'Otros impuestos (SE/NIIT)';

  @override
  String get exportHeader => 'Exportar';

  @override
  String get exportPdf => 'Paquete imprimible de la declaración';

  @override
  String get exportMef => 'JSON listo para e-file';

  @override
  String get savedPackage => 'Paquete guardado.';

  @override
  String get savedMef => 'JSON guardado.';

  @override
  String get mefDisclaimer => 'El JSON refleja conceptos del MeF del IRS para portabilidad. No se transmite a ningún lugar y el IRS no lo acepta directamente.';

  @override
  String get exportFailed => 'Error al exportar';

  @override
  String get startNewReturn => 'Iniciar nueva declaración';

  @override
  String get openReturnFile => 'Abrir archivo de declaración (.nnx)';

  @override
  String get importFromOther => 'Importar de TurboTax / CSV / texto';

  @override
  String get continueLastReturn => 'Continuar mi última declaración';

  @override
  String get welcomeTagline => 'Una declaración guiada, de código abierto y limpia, para el impuesto federal 2024 y 2025: sus datos se quedan en su dispositivo.';

  @override
  String get welcomePrivacyNote => 'Nitro Nissi guarda todo localmente. La IA es opcional y solo usa las claves gratuitas que usted proporcione.';

  @override
  String openFailed(String error) {
    return 'No se pudo abrir el archivo: $error';
  }

  @override
  String get eligibilityTitle => 'Verificación rápida de elegibilidad';

  @override
  String get eligQ1 => '¿Fue ciudadano(a) o residente de EE. UU. todo el año?';

  @override
  String get eligQ2 => '¿Usted (y su cónyuge, si declaran juntos) tienen SSN válidos?';

  @override
  String get eligQ3 => '¿Sus ingresos son solo de sueldos, trabajo independiente, intereses, dividendos, inversiones, jubilación, Seguro Social o desempleo?';

  @override
  String get eligQ4 => '¿Sin rentas, K-1, ingresos agrícolas, cuentas extranjeras ni quiebra este año?';

  @override
  String get answerYes => 'Sí';

  @override
  String get answerNo => 'No';

  @override
  String get eligOkTitle => '¡Bien! Nitro Nissi sirve para su situación';

  @override
  String get eligOkBody => 'Puede completar una declaración federal aquí con confianza. Revisará todo antes de exportar.';

  @override
  String get eligPartialTitle => 'Puede continuar, con cuidado';

  @override
  String get eligPartialBody => 'Algunas respuestas sugieren que partes de sus impuestos pueden requerir un profesional o software avanzado. Nitro Nissi señalará lo que no pueda manejar por completo.';

  @override
  String get eligContinue => 'Continuar a mi declaración';

  @override
  String get askPlaceholder => 'Pregunte algo sobre su declaración…';

  @override
  String get quickReviewReturn => 'Revisar mi declaración';

  @override
  String get quickDeductions => '¿Qué me falta?';

  @override
  String get quickExplain => 'Explicar AGI y deducciones';

  @override
  String get settingsAiHeader => 'Asistente IA';

  @override
  String get googleKeyTitle => 'Google AI Studio (Gemini): clave API gratuita';

  @override
  String get googleKeySteps => '1. Abra aistudio.google.com/apikey e inicie sesión con una cuenta de Google.\n2. Haga clic en \"Create API key\" (elija o cree un proyecto).\n3. Copie la clave (empieza con AIza…) y péguela abajo. El nivel gratuito incluye límites diarios por modelo.';

  @override
  String get googleKeyLink => 'Obtener clave gratuita de Google AI Studio →';

  @override
  String get mistralKeyTitle => 'Mistral La Plateforme: clave API gratuita';

  @override
  String get mistralKeySteps => '1. Abra console.mistral.ai/api-keys y cree una cuenta gratuita (el plan \"Experiment\" no requiere tarjeta).\n2. Haga clic en \"Create new key\", asígnele nombre y cópiela.\n3. Péguela abajo. El plan gratuito permite ~1 solicitud/segundo y 500k tokens/minuto.';

  @override
  String get mistralKeyLink => 'Obtener clave gratuita de Mistral →';

  @override
  String get chainHeader => 'Cadena de respaldo de modelos';

  @override
  String get testChain => 'Probar';

  @override
  String get chainNote => 'Nitro Nissi prueba el primer modelo y, si falta clave, el modelo no está disponible o se alcanzan los límites gratuitos, pasa automáticamente al siguiente. Reordene o desactive a gusto.';

  @override
  String get automationHeader => 'Automatización y privacidad';

  @override
  String get toggleShareContext => 'Permitir que el asistente vea un resumen de mi declaración';

  @override
  String get toggleAnonymize => 'Anonimizar datos personales (nombres, SSN) en solicitudes de IA';

  @override
  String get toggleAutoDeductions => 'Sugerir deducciones que suelen olvidarse';

  @override
  String get toggleAutoExtract => 'Extraer números de documentos pegados automáticamente';

  @override
  String get appearanceHeader => 'Apariencia e idioma';

  @override
  String get themeLabel => 'Tema';

  @override
  String get languageLabel => 'Idioma';

  @override
  String couldNotOpen(String url) {
    return 'No se pudo abrir $url';
  }

  @override
  String get importTitle => 'Importar';

  @override
  String get importIntro => 'Traiga datos de un archivo de TurboTax (mejor esfuerzo: su formato es propietario), un CSV, nuestros archivos .nnx, o pegue el texto de un W-2/1099 y deje que la IA extraiga los números. Siempre revisa antes de aplicar.';

  @override
  String get chooseFile => 'Elegir archivo…';

  @override
  String get extractPasted => 'Extraer del texto pegado';

  @override
  String get pasteLabel => 'Pegue aquí el texto del documento';

  @override
  String get pasteHint => 'ej. copie el texto de un W-2 o 1099…';

  @override
  String get detectedFormat => 'Detectado';

  @override
  String get reviewImportNote => 'Conserve solo los campos que verificó. La importación nunca sobrescribe sin sus casillas.';

  @override
  String get nothingFound => 'No se encontraron campos tributarios reconocibles. Los archivos TurboTax recientes pueden estar cifrados o usar un formato no documentado: vea docs/FILE_FORMATS.md.';

  @override
  String applyFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count campos',
      one: '1 campo',
    );
    return 'Aplicar $_temp0';
  }

  @override
  String get importFaq => '¿Por qué mejor esfuerzo? Los formatos de Intuit son cerrados y no documentados; analizamos estructuras de contenedores y coincidencias de etiquetas con cautela, y nunca intentamos vencer cifrado. docs/REVERSE_ENGINEERING_PLAN.md describe nuestra hoja de ruta clean-room.';

  @override
  String get importNotePreview => 'Revise cada campo detectado, conserve lo verificado y aplique.';

  @override
  String get importNoteZipEncrypted => 'Es un contenedor ZIP, pero parece cifrado o no estándar. Intente exportar un CSV/PDF desde la otra aplicación.';

  @override
  String get importNoteOle2NoFields => 'Es un contenedor OLE2 (Compound File). No se hallaron campos tributarios reconocibles en sus flujos.';

  @override
  String get importNoteOle2Unknown => 'Es un contenedor OLE2 (Compound File), pero su contenido no se pudo analizar.';

  @override
  String get importNoteUnknown => 'Tipo de archivo no reconocido. Soportados: .nnx, JSON, CSV, texto plano y análisis estructural de archivos propietarios.';

  @override
  String get importErrorUnknown => 'Algo falló al leer ese archivo.';
}
